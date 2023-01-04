const Web3 = require("web3");
require("dotenv").config();

const ABI = require("../artifacts/contracts/LSP8Marketplace.sol/LSP8Marketplace.json");

const web3 = new Web3("https://rpc.l16.lukso.network/");

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const myAccount = web3.eth.accounts.privateKeyToAccount(PRIVATE_KEY);

web3.eth.accounts.wallet.add(myAccount.privateKey);

const myContract = new web3.eth.Contract(ABI.abi, {
  gas: 5_000_000,
  gasPrice: "1000000000",
});

myContract
  .deploy({
    data: ABI.bytecode,
    arguments: ["FAMILY"],
  })
  .send({
    from: myAccount.address,
  })
  .on("error", function (error) {
    console.log(error);
  })
  .on("transactionHash", function (transactionHash) {
    console.log("txHash: ", transactionHash);
  })
  .on("receipt", function (receipt) {
    console.log("receipt: ", receipt.contractAddress); // contains the new contract address
  })
  .on("confirmation", function (confirmationNumber, receipt) {
    console.log("confirmation: ", confirmationNumber);
  })
  .then(function (newContractInstance) {
    console.log(newContractInstance.options.address); // instance with the new contract address
  });
