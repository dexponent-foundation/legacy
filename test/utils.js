const deployProxy = async (contractName, signer, proxyName) => {
    const clETHInstance = await ethers.getContractFactory(contractName, signer);
    const clethContract = await clETHInstance.deploy();
    const TokenProxy = await ethers.getContractFactory(proxyName, signer);

    const proxy = await TokenProxy.deploy(clethContract.address, signer.address, "0x");
    await proxy.setAdmin();
    await proxy.getAdmin();
    return await ethers.getContractAt(contractName, proxy.address);
}
exports.deployProxy = deployProxy;
