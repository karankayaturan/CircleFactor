// scripts/deploy.js

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // Deploy InvoiceNFT contract
    const InvoiceNFT = await ethers.getContractFactory("InvoiceNFT");
    const invoiceNFT = await InvoiceNFT.deploy("0xf08a50178dfcde18524640ea6618a1f965821715");
    await invoiceNFT.deployed();
    console.log("InvoiceNFT deployed to:", invoiceNFT.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
