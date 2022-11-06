task("create-project", "Add new Data Project")
  .addParam("contract", "The address the ProjectFactory contract")
  .addParam("goalamount", "Target amount for funding")
  .addParam("cid", "CID of Data")
  .addParam("datasize", "Target amount for pool")
  .setAction(async (taskArgs) => {
    const contractAddr = taskArgs.contract
    const goalAmount = taskArgs.goalAmount
    const cid = taskArgs.cid
    const dataSize = taskArgs.dataSize
    const networkId = network.name
    // console.log("Deploy new data project for funding", account, " on network ", networkId)
    const ProjectFactory = await ethers.getContractFactory("ProjectFactory")

    //Get signer information
    const accounts = await ethers.getSigners()
    const signer = accounts[0]


    const projectFactoryContract = new ethers.Contract(contractAddr, ProjectFactory.interface, signer)
    let result = (await projectFactoryContract.create(goalAmount, cid, dataSize)).toString()
    console.log("Data is: ", result)
  })

module.exports = {}