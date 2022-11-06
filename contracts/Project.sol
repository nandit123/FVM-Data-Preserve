//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Project is ERC721 {
    uint256 public constant MINIMUM_CONTRIBUTION = 0.01 ether;

    address public creator;
    uint256 public goalAmount;
    uint256 public deadline;
    string public cid;
    uint256 public dataSize;

    enum ProjectStatus {
        ACTIVE,
        SUCCESS,
        FAILURE
    }
    bool isCancelled;

    // Ether held by the contract on behalf of contributors/pledgers
    mapping(address => uint256) public contributionOf;
    // Badge status held by the contract on behalf of contributors/pledgers
    mapping(address => uint256) public badgeOf;

    uint256 public totalContribution;
    uint256 public remainingContribution;

    event ContributionMade(address indexed contributor, uint256 amount);
    event WithdrawalMade(uint256 amount);
    event RefundMade(address indexed contributor, uint256 amount);
    event CancellationMade();

    constructor(address _creator, uint256 _goalAmount, string memory _cid, uint256 _dataSize)
        ERC721("Project Contribution Badge", "PCB")
    {
        creator = _creator;
        goalAmount = _goalAmount;
        cid = _cid;
        dataSize = _dataSize;
        deadline = block.timestamp + 30 days;
    }

    modifier onlyCreator() {
        require(
            msg.sender == creator,
            "This operation could only be done by the creator"
        );
        _;
    }

    function checkStatus() private view returns (ProjectStatus) {
        if (totalContribution >= goalAmount) {
            return ProjectStatus.SUCCESS;
        } else {
            if (isCancelled || block.timestamp >= deadline) {
                return ProjectStatus.FAILURE;
            }
        }

        return ProjectStatus.ACTIVE;
    }

    function contribute() external payable {
        require(!isCancelled, "PROJECT_IS_CANCELLED");
        require(checkStatus() == ProjectStatus.ACTIVE, "PROJECT_IS_NOT_ACTIVE");
        require(msg.value >= MINIMUM_CONTRIBUTION, "TOO_LOW_CONTRIBUTION");

        uint256 previousContribution = contributionOf[msg.sender];
        contributionOf[msg.sender] += msg.value;
        totalContribution += msg.value;
        remainingContribution += msg.value;

        // Note: Upper and floor function don't exist so * 1 ether and / 1 ether are being used here e.g. / 1 ether + 1 is upper function then * 1 ether to change it back to ether
        if (
            contributionOf[msg.sender] >=
            (previousContribution / 1 ether + 1) * 1 ether
        ) {
            uint256 additionalBadge = ((contributionOf[msg.sender] / 1 ether) -
                badgeOf[msg.sender]) / 1;

            badgeOf[msg.sender] += additionalBadge;
            _mint(msg.sender, badgeOf[msg.sender]);
        }

        emit ContributionMade(msg.sender, msg.value);
    }

    // TODO: The difference between payable in .call vs payable in the function declaration
    function withdrawFunds(uint256 amountToWithdraw) external onlyCreator {
        require(
            checkStatus() == ProjectStatus.SUCCESS,
            "project is not SUCCESS"
        );
        require(
            totalContribution >= goalAmount,
            "project is not fully funded yet"
        );
        require(
            amountToWithdraw <= remainingContribution,
            "you do not have enough balance"
        );

        remainingContribution -= amountToWithdraw;
        (bool success, ) = (msg.sender).call{value: amountToWithdraw}("");
        require(success, "withdrawal failed");

        emit WithdrawalMade(amountToWithdraw);
    }

    function refundContributions() external {
        require(
            checkStatus() == ProjectStatus.FAILURE,
            "project is not FAILURE"
        );

        uint256 amount = contributionOf[msg.sender];
        require(amount > 0, "no money to brefunded");

        contributionOf[msg.sender] = 0;
        (bool success, ) = (msg.sender).call{value: amount}("");
        require(success, "refund failed");

        emit RefundMade(msg.sender, amount);
    }

    function cancelProject() external onlyCreator {
        require(
            checkStatus() == ProjectStatus.ACTIVE,
            "cancellation could not be after 30 days passed"
        );

        isCancelled = true;

        emit CancellationMade();
    }
}