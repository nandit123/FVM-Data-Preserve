//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {Project} from "./Project.sol";

contract ProjectFactory {
    Project[] public projects;

    event ProjectCreated(
        address indexed creator,
        address project,
        uint256 _goalAmount,
        string _cid,
        uint256 _dataSize
    );

    function create(uint256 _goalAmount, string memory _cid, uint256 _dataSize) external {
        Project project = new Project(msg.sender, _goalAmount, _cid, _dataSize);
        projects.push(project);

        emit ProjectCreated(msg.sender, address(project), _goalAmount, _cid, _dataSize);
    }

    function getProjects() public view returns (Project[] memory) {
        return projects;
    }
}