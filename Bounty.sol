// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BountyManager {
    address public manager;
    
    enum State { Open, Closed }

    struct Submission {
        address submitter;
        string description;
        bool approved;
    } 

    struct Bounty{
        address owner;
        string description;
        uint reward;
        uint deadline;
        State state;
        uint numSubmission;
        mapping(uint=>Submission) submissionList;
    }

    Bounty[] public bountyList;

    event BountyCreated(address creator, string description, uint reward, uint deadline);
    event SubmissionReceived(address submitter, string description);
    event WinnerSelected(address winner, uint reward);

    constructor() {
        manager = msg.sender;
    }

    function createBounty(string memory _description, uint _reward, uint _deadline) public payable {
        // check whether sender sent equal money
        require(_reward < msg.value, "Not enough Balance.");
        // check deadline is correct (can be done on frontend too)
        Bounty storage newBounty = bountyList.push();
        newBounty.owner = msg.sender;
        newBounty.description = _description;
        newBounty.reward = _reward;
        newBounty.deadline = _deadline;
        newBounty.state = State.Closed;
        
        emit BountyCreated(msg.sender, _description, _reward, _deadline);
    }

    //returns number of available bounties
    function getNumBounties() public view returns (uint) {
        uint availBounties = 0;
       for (uint i = 0; i < bountyList.length; i++) {
            if (bountyList[i].deadline > block.timestamp) {
                availBounties++;
            }
        }
        return availBounties ;
    }
    
    //closes bounty if deadline reached 
    function closeBountyIfDeadlineReached(uint bountyIndex) public {
        require(bountyIndex < bountyList.length, "Invalid bounty index");
        Bounty storage bounty = bountyList[bountyIndex];
        require(bounty.deadline < block.timestamp, "Deadline has not passed yet");
        require(bounty.state == State.Open, "Bounty is not open");
        bounty.state = State.Closed;
    }
    


    // function to retrive all the bounty in which user has particiapted 

    // update according to the bounty submission
    function bountySubmission(uint bountyIndex, string memory _description) public {
        require(bountyIndex < bountyList.length,"bountyIndex out of Range.");
        Bounty storage bounty = bountyList[bountyIndex];
        Submission storage s = bounty.submissionList[bounty.numSubmission++];
        s.submitter = msg.sender;
        s.description = _description;
        s.approved = false;
        emit SubmissionReceived(msg.sender, _description);
        require(bounty.deadline > block.timestamp, "Deadline has not passed yet."); //this will ensure submissions occur before deadline

    }
    
    //returns number of submissions made for any bounty
    function getNumSubmissionsForBounty(uint bountyIndex) public view returns (uint) {
        require(bountyIndex < bountyList.length, "Invalid bounty index");
        return bountyList[bountyIndex].numSubmission;
    }


    // update according to the bounty submission
    // also update the payable method to support multiple winners
    
    function selectBountyWinner(uint bountyIndex, uint[] memory _submissionIndexes) public {
        require(bountyIndex < bountyList.length,"bountyIndex out of Range."); //removed length -1 to access the last bounty
        Bounty storage bounty = bountyList[bountyIndex];
        require(bounty.state == State.Closed, "Bounty is not closed yet.");
        require(bounty.deadline < block.timestamp, "Deadline has not passed yet.");   //this will ensure winner is selected after deadline
    
        for (uint i = 0; i < _submissionIndexes.length; i++) {
            uint submissionIndex = _submissionIndexes[i];
            require(submissionIndex < bounty.numSubmission, "Invalid submission index.");
            require(!bounty.submissionList[submissionIndex].approved, "This submission has already been approved.");
            bounty.submissionList[submissionIndex].approved = true;
            payable(bounty.submissionList[submissionIndex].submitter).transfer(bounty.reward / _submissionIndexes.length);
            emit WinnerSelected(bounty.submissionList[submissionIndex].submitter, bounty.reward / _submissionIndexes.length);
        }
}

    //return all the submissions for a bounty using index
    function getBountySubmissionByIndex(uint bountyIndex, uint submissionIndex) view public returns(Submission memory){
        require(bountyIndex < bountyList.length,"bountyIndex out of Range."); //removed length -1 to access the last bounty
        Bounty storage bounty = bountyList[bountyIndex];
        return bounty.submissionList[submissionIndex];
    }

    //returns timeleft before deadline
    function getTimeLeft(uint bountyIndex) public view returns (uint) {
    require(bountyIndex < bountyList.length, "Bounty index out of range.");
    Bounty storage bounty = bountyList[bountyIndex];
    require(bounty.deadline > block.timestamp, "Deadline has passed.");
    return bounty.deadline - block.timestamp;
    }


    //to select winners(multiple allowed)
    function getSelectedWinners(uint bountyIndex) public view returns (address[] memory) {
    require(bountyIndex < bountyList.length, "Invalid bounty index");
    Bounty storage bounty = bountyList[bountyIndex];
    address[] memory winners = new address[](bounty.numSubmission);
    uint numWinners = 0;

    for (uint i = 0; i < bounty.numSubmission; i++) {
        if (bounty.submissionList[i].approved) {
            winners[numWinners] = bounty.submissionList[i].submitter;
            numWinners++;
        }
    }

    // Create a new array with the correct length and copy the winners into it
    address[] memory resizedWinners = new address[](numWinners);
    for (uint i = 0; i < numWinners; i++) {
        resizedWinners[i] = winners[i];
    }

    return resizedWinners;
}



}
