// contracts/InvoiceNFT.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./kUSDC.sol";

contract InvoiceNFT is ERC721, Ownable {
    // all periods are 30 days
    // the bank buys the invoice by their 90% of value
    struct Invoice {  
        uint256 value;
        uint256 dailyGain; // increase of KUSDC daily
    }

    mapping(uint256 => Invoice) public invoices;
    uint256 public invoiceCount;

    event InvoiceCreated(uint256 indexed invoiceId, uint256 value, uint256 dailyGain);
    event Invested(uint256 indexed invoiceId, address indexed investor, uint256 investedAmount);

    // constructor

    IERC20 immutable _usdcAddress;
    KUSDC immutable _kUSDC;

    constructor(address usdcAddress) Ownable(msg.sender) ERC721("InvoiceNFT", "INVOICE") {
        _usdcAddress = IERC20(usdcAddress);
        _kUSDC = new KUSDC(address(this));
    }

    // The SME must use this function to create invoice NFT.
    // In return he/she will receive the 90% of the value as USDC 
    function createInvoice(uint256 _value, uint256 _dailyGain) external onlyOwner {
        require(_value > 0, "value needs to be higher");

        // check if bank has deposited enough money
        IERC20 usdc = IERC20(_usdcAddress);
        uint256 bankFunds = usdc.balanceOf(address(this));
        require(bankFunds * 90 > _value * 100, "insufficient bank funds");

        // transfer the 90% of the value as USDC
        uint256 amountToPaid = _value * 90 / 100;
        require(usdc.transfer(msg.sender, amountToPaid), "unable to pay the sme");

        // mint the NFT to the sme 
        uint256 invoiceId = invoiceCount++;
        _mint(msg.sender, invoiceId);

        // save the invoice details
        invoices[invoiceId] = Invoice({
            value: _value,
            dailyGain: _dailyGain
        });

        emit InvoiceCreated(invoiceId, _value, _dailyGain);
    }

    // The investor must use this function to invest into an invoice NFT.
    // Investor must approve the amount of USDC that wants to invest.
    function invest(uint256 invoiceId, uint256 _value) external {
        require(_ownerOf(invoiceId) != address(0), "invoice doesn't exist");
        require(_value > 0, "insufficient value to invest");

        // try to transfer USDC from the investor to the contract
        require(
            IERC20(_usdcAddress).transferFrom(msg.sender, address(this), _value),
            "unable to transfer invested amount"
        );

        Invoice memory details = invoices[invoiceId];

        // all invoices are supposed to end in 1 month.
        // mint KUSDC to the investor
        uint256 kUSDCtoMint = _value + (_value * (details.dailyGain * 30 days));
        _kUSDC.mint(msg.sender, kUSDCtoMint);
        
        emit Invested(invoiceId, msg.sender, _value);
    }

    // todo 
    // The bank must allocate some money for the investors to swap their kUSDC to USDC
    function payInvoiceShares(uint256 invoiceId, uint256 totalValueToDistribute) external onlyOwner {

    }

    // todo
    // The investor must use this function to swap their kUSDC shares for the revenue of the invoice.
    // The investor must approve kUSDC to this contract to fulfill.
    function collectShareReward(uint256 invoiceId, uint256 kUSDCtoBurn) external {

    }
}
