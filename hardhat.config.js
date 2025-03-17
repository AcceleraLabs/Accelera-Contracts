/** @type import('hardhat/config').HardhatUserConfig */
require('dotenv').config()

const ACCELERA_DEV_PK = process.env.ACCELERA_DEV_PK
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY

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

  defaultNetwork: "mainnet",

  networks : {
    mainnet: {
      url: 'https://eth.drpc.org',
      chainId : 1,
      accounts : [ACCELERA_DEV_PK]
    },
  },
  
  etherscan: {
    apiKey: {
      mainnet: ETHERSCAN_API_KEY,
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
    ]
  }
}
