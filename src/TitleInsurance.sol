// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Property.sol";
import "./Title.sol";


contract TitleInsurance is Ownable {

  struct InsurancePolicy {
    address owner;
    uint256 propertyTokenId;
    uint256 premiumAmount;
    uint256 coverAmount;
    bool isActive;
  }

  struct Claim {
    uint256 policyId;
    uint256 amount;
    string reason;
    bool isApproved;
  }

  struct Payout {
    uint256 amount;
  }

  struct PremiumPayment {
    uint256 amount;
  }

  address[] public backersAddresses;
  mapping(address => uint256) public backersInitialBalance;
  mapping(address => uint256) public backersInterestBalance;
  uint256 public totalPoolBalance;
  uint256 public poolShare = 0.01 ether;

  mapping(uint256 => InsurancePolicy) public policies;
  mapping(uint256 => Claim) public claims;
  uint256 public nextPolicyId = 1;
  uint256 public nextClaimId = 1;
  bool initialBalanceWithdrawEnabled = false;

  event BackerFunded(address backer, uint256 amount);
  event PolicyCreated(uint256 policyId);
  event ClaimSubmitted(uint256 claimId);
  event ClaimApproved(uint256 claimId, uint256 payoutAmount);
  event InitialBalanceWithdrawEnabledChanged(address owner, bool value);
  event WithdrawInitialBalance(address backer, uint256 amount);
  event WithdrawInterest(address backer, uint256 amount);
  event PremiumPaid(address propertyOwner, uint256 policyId);
  event PolicyAdded(uint256 policyId);
  event ClaimAdded(uint256 claimId);
  event ClaimPaidOut(uint256 claimId, address propertyOwner, uint256 amount);

  Title public title;
  Property public property;

  constructor(address _title, address _property, address initialOwner)
    Ownable(initialOwner)
  {
    title = Title(_title);
    property = Property(_property);
  }

  function setInitialBalanceWithdrawEnabled(bool value) external onlyOwner {
    require(initialBalanceWithdrawEnabled == !value, "Value already set");
    initialBalanceWithdrawEnabled = value;
    emit InitialBalanceWithdrawEnabledChanged(owner(), value);
  }

  function backPool() external payable {
    require(msg.value == poolShare, "Amount mismatch");
    backersAddresses.push(msg.sender);
    backersInitialBalance[msg.sender] += msg.value;
    totalPoolBalance += msg.value;
    emit BackerFunded(msg.sender, msg.value);
  }

  // If the owner allowed, the initial balance can be withdrawn, only in full
  function withdrawInitialBalance() external {
    require(initialBalanceWithdrawEnabled == true, "Withdrawal is not allowed");
    require(backersInitialBalance[msg.sender] >= 0, "Insufficient funds");
    uint256 amount = backersInitialBalance[msg.sender];
    backersInitialBalance[msg.sender] -= amount;
    totalPoolBalance -= amount;
    emit WithdrawInitialBalance(msg.sender, amount);
    payable(msg.sender).transfer(amount);
  }

  function distributeFunds(uint256 amount) internal {
    uint256 length = backersAddresses.length;
    // get the number of all backers who didn't withdraw the initial balance;
    uint256 currentBackersNumber;
    for (uint256 i = 0; i < length; i++) {
      address currentBacker = backersAddresses[i];
      if (backersInitialBalance[currentBacker] > 0) {
        currentBackersNumber++;
      }
    }
    // distribute interest to all backers who have positive balance
    for (uint256 i = 0; i < length; i++) {
      address currentBacker = backersAddresses[i];
      // Ensure the backer's balance is not already zero to prevent underflow
      if (backersInitialBalance[currentBacker] > 0) {
        backersInterestBalance[msg.sender] += (amount / currentBackersNumber);
      }
    }
  }

  // when property owner changed, terminate the policy and distribute the premium
  function terminatePolicy(uint256 policyId) external onlyOwner {
    InsurancePolicy storage policy = policies[policyId];
    require(policy.isActive, "Policy is not active");
    policy.isActive = false;
    distributeFunds(policy.premiumAmount);
  }

  function withdrawInterest() external {
    uint256 amount = backersInterestBalance[msg.sender];
    require(amount > 0, "No interest so far");
    backersInterestBalance[msg.sender] -= amount;
    totalPoolBalance -= amount;
    emit WithdrawInterest(msg.sender, amount);
    payable(msg.sender).transfer(amount);
  }

  function createPolicy(address owner, uint256 propertyId, uint256 premiumAmount, uint256 coverAmount) external onlyOwner {
    //require(property.propertyOwners[propertyId] == msg.sender, "Not the property owner");
    policies[nextPolicyId] = InsurancePolicy(owner, propertyId, premiumAmount, coverAmount, false);
    nextPolicyId += 1;
    //return --nextPolicyId;
  }

  function submitClaim(uint256 policyId, uint256 amount, string memory reason) public onlyOwner {
    require(policies[policyId].owner == msg.sender, "Not the policy holder");
    //require(!policies[policyId].hasClaim, "Claim already submitted for this policy");
    claims[nextClaimId] = Claim(policyId, amount, reason, false);
    //policies[policyId].hasClaim = true;
    nextClaimId += 1;
  }

  function approveClaim(uint256 claimId) public onlyOwner {
    // Only a trusted entity (like an oracle or a multi-sig) should be able to approve claims.
    // In this example, we're allowing any backer to approve for simplicity.
    // In a real-world scenario, this approach would be unsafe.
    claims[claimId].isApproved = true;
    InsurancePolicy memory policy = policies[claims[claimId].policyId];
    require(totalPoolBalance >= policy.coverAmount, "Insufficient funds in pool");
    totalPoolBalance -= policy.coverAmount;
    payable(policy.owner).transfer(policy.coverAmount);
  }


  function payPremium(uint256 policyId) external payable {
    InsurancePolicy storage policy = policies[policyId];
    require(msg.sender == policy.owner, "Not the owner of the policy");
    //require(msg.value == policy.premiumAmount, "Incorrect premium amount");
    //require(policy.isActive == false, "Policy already active");

    totalPoolBalance += msg.value;
    policy.isActive = true;
    emit PremiumPaid(msg.sender, policyId);
  }

  function addPolicy(address payable propertyOwner, uint256 propertyTokenId, uint256 premiumAmount, uint256 coverageAmount) external onlyOwner {
    policies[nextPolicyId] = InsurancePolicy(propertyOwner, propertyTokenId, premiumAmount, coverageAmount, false);
    emit PolicyAdded(nextPolicyId);
    nextPolicyId++;
  }

  function addClaim(uint256 policyId, uint256 claimedAmount, string calldata reason) external onlyOwner {
    InsurancePolicy storage policy = policies[policyId];
    require(policy.isActive, "Policy not active");

    claims[nextClaimId] = Claim(policyId, claimedAmount, reason, false);
    emit ClaimAdded(nextClaimId);
    nextClaimId++;
  }

  function approveAndPayoutClaim(uint256 claimId) external onlyOwner {
    Claim storage claim = claims[claimId];
    InsurancePolicy storage policy = policies[claim.policyId];

    require(claim.isApproved == false, "Claim already approved");
    require(totalPoolBalance >= claim.amount, "Insufficient pool balance");
    require(claim.amount <= policy.coverAmount, "Claimed amount exceeds policy coverage");

    claim.isApproved = true;
    totalPoolBalance -= claim.amount;
    payable(policy.owner).transfer(claim.amount);
    emit ClaimPaidOut(claimId, policy.owner, claim.amount);
  }
}

