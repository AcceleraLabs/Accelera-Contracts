/** @type import('hardhat/config').HardhatUserConfig */
require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");

require('dotenv').config()

const ACCELERA_DEV_PK = process.env.ACCELERA_DEV_PK
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY
const BLAST_API_KEY = process.env.BLAST_API_KEY
const LOCAL_TEST_PK_0 = process.env.LOCAL_TEST_PK_0
const LOCAL_TEST_PK_1 = process.env.LOCAL_TEST_PK_1
const ACCELERA_DEV_TEST_PK = process.env.ACCELERA_DEV_TEST_PK

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.28",
        settings: {
          optimizer: {
            enabled : true,
            runs: 2048,
          }
        }
      },
    ]
  },

  defaultNetwork: "blast_sepolia",

  networks : {
    mainnet: {
      url: 'https://eth.drpc.org',
      chainId : 1,
      accounts : [ACCELERA_DEV_PK]
    },
    local: {
      url: 'http://127.0.0.1:8545/',
      chainId : 31337,
      accounts : [LOCAL_TEST_PK_0,LOCAL_TEST_PK_1]
    },
    blast_sepolia: {
      url: 'https://endpoints.omniatech.io/v1/blast/sepolia/public',
      chainId : 168587773 ,
      accounts : [ACCELERA_DEV_TEST_PK]
    },
  },
  
  etherscan: {
    apiKey: {
      mainnet: ETHERSCAN_API_KEY,
      blast_sepolia: BLAST_API_KEY,
    },
    customChains: [
      {
        network: "mainnet",
        chainId: 1,
        urls: {
          apiURL: `https://api.etherscan.io/api?apiKey=${ETHERSCAN_API_KEY}`,
          browserURL: "https://etherscan.io/"
        }
      },
      {
        network:"blast_sepolia",
        chainId: 168587773,
        urls: {
          apiURL: `https://api-sepolia.blastscan.io/api?apiKey=${BLAST_API_KEY}`,
          browserURL: "https://blastscan.io/"
        }

      },
    ]
  }
}
