import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-tracer";
const config: HardhatUserConfig = {
   solidity: "0.8.18",
  networks:{
	  hardhat:{
		chainId:10,
		
		  forking:{

			  url:"https://optimism-mainnet.infura.io/v3/2dff452478174fdf8035dc20eadb5667",
			
			// url:"https://optimism-goerli.infura.io/v3/2dff452478174fdf8035dc20eadb5667"
		  }
	  },
   


},
mocha: {
  timeout: 8000000,
},
}

export default config;
