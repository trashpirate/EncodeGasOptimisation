// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./Ownable.sol";

// set to constant and remove unused variable -> 80055
// removing inheritance does not change gas
contract Constants {
    uint8 constant tradeFlag = 1;
    uint8 constant dividendFlag = 1;
}

contract GasContract is Ownable, Constants {
    uint256 public immutable totalSupply; // cannot be updated, set to immutable -> saves 16472
    uint256 private paymentCounter; // set to private -> saves 7614, not setting to 0 -> saves 2209
    mapping(address => uint256) public balances;

    address private immutable contractOwner; // set to private -> saves 9415, set to immutable -> saves 7660
    // uint256 public tradeMode = 0; // remove dead code -> saves 23031
    mapping(address => Payment[]) private payments; // setting to private -> 75487
    mapping(address => uint256) public whitelist;
    address[5] public administrators;
    // bool public isReady = false; // reomve dead code -> saves 13636
    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }
    PaymentType constant defaultPayment = PaymentType.Unknown;

    History[] private paymentHistory; // when a payment was updated, setting to private -> saves 30436

    // reordering of structs -> saves 3400
    struct Payment {
        bool adminUpdated;
        uint256 paymentID;
        uint256 amount;
        string recipientName; // max 8 characters
        address recipient;
        address admin; // administrators address
        PaymentType paymentType;
    }

    struct History {
        uint256 lastUpdate;
        uint256 blockNumber;
        address updatedBy;
    }
    // uint256 wasLastOdd = 1; // removed unused variable -> saves 22106
    // mapping(address => uint256) private isOddWhitelistUser; // setting to private -> saves 12215, remove -> saves

    // remove unused -> saves 9614
    struct ImportantStruct {
        uint256 amount;
        bool paymentStatus;
        address sender;
    }
    mapping(address => ImportantStruct) private whiteListStruct; // setting to private -> saves 35636

    event AddedToWhitelist(address userAddress, uint256 tier);

    // refactoring -> saves 196610
    modifier onlyAdminOrOwner() {
        require(
            checkForAdmin(msg.sender) || msg.sender == contractOwner,
            "Gas Contract: Caller not admin" // shorten error -> saves 5007
        );
        _;
    }

    // shorten errors -> saves 68472
    // remove dead code -> saves 1000
    modifier checkIfWhiteListed(address sender) {
        // address senderOfTx = msg.sender;
        // require(senderOfTx == sender, "Gas Contract: Origin not Sender");
        // uint256 usersTier = whitelist[msg.sender];
        require(
            whitelist[msg.sender] > 0,
            "Gas Contract: User is not whitlisted"
        ); // remove unused code -> 17421
        _;
    }

    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(
        address admin,
        uint256 ID,
        uint256 amount,
        string recipient
    );
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        // msg.sender -> saves 22729
        contractOwner = msg.sender;
        totalSupply = _totalSupply; // use calldata -> saves 97

        for (uint256 ii = 0; ii < administrators.length; ii++) {
            // zero address check -< saves 535
            administrators[ii] = _admins[ii];
            if (_admins[ii] == msg.sender) {
                balances[msg.sender] = _totalSupply;
                emit supplyChanged(_admins[ii], _totalSupply);
            }
        }
    }

    function getPaymentHistory()
        public
        payable
        returns (History[] memory paymentHistory_)
    {
        return paymentHistory;
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        bool admin = false;
        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (administrators[ii] == _user) {
                admin = true;
            }
        }
        return admin;
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        uint256 balance = balances[_user];
        return balance;
    }

    // saves 9806
    // function getTradingMode() public pure returns (bool mode_) {
    //     return true;
    // }
    // change return value -> saves 20827

    function addHistory(address _updateAddress) public {
        History memory history;
        history.blockNumber = block.number;
        history.lastUpdate = block.timestamp;
        history.updatedBy = _updateAddress;
        paymentHistory.push(history);
        // saves 33642
        // bool[] memory status = new bool[](tradePercent);
        // for (uint256 i = 0; i < tradePercent; i++) {
        //     status[i] = true;
        // }
        // return true;
    }

    // shorten all error strings below -> saves 114128

    // remove code -> saves 175384
    // function getPayments(
    //     address _user
    // ) public view returns (Payment[] memory payments_) {
    //     require(_user != address(0), "Gas Contract: Invalid address");
    //     return payments[_user];
    // }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public returns (bool status_) {
        // address senderOfTx = msg.sender; // saves 4407
        require(
            balances[msg.sender] >= _amount,
            "Gas Contract: Insufficient Balance"
        );
        require(
            bytes(_name).length < 9,
            "Gas Contract:  Max name length exceeded"
        );
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);
        Payment memory payment;
        payment.admin = address(0);
        payment.adminUpdated = false;
        payment.paymentType = PaymentType.BasicPayment;
        payment.recipient = _recipient;
        payment.amount = _amount;
        payment.recipientName = _name;
        payment.paymentID = ++paymentCounter;
        payments[msg.sender].push(payment);
        // remove dead code -> saves 33033
        // bool[] memory status = new bool[](tradePercent);
        // for (uint256 i = 0; i < tradePercent; i++) {
        //     status[i] = true;
        // }
        return true;
    }

    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) public onlyAdminOrOwner {
        require(_ID > 0, "Gas Contract: Invalid ID");
        require(_amount > 0, "Gas Contract: Invalid amount");
        require(_user != address(0), "Gas Contract : Invalid admin address");

        // address senderOfTx = msg.sender; saves 400

        for (uint256 ii = 0; ii < payments[_user].length; ii++) {
            if (payments[_user][ii].paymentID == _ID) {
                payments[_user][ii].adminUpdated = true;
                payments[_user][ii].admin = _user;
                payments[_user][ii].paymentType = _type;
                payments[_user][ii].amount = _amount;
                // bool tradingMode = getTradingMode();
                addHistory(_user);
                emit PaymentUpdated(
                    msg.sender,
                    _ID,
                    _amount,
                    payments[_user][ii].recipientName
                );
            }
        }
    }

    function addToWhitelist(
        address _userAddrs,
        uint256 _tier
    ) public onlyAdminOrOwner {
        require(_tier < 255, "Gas Contract: Invalid tier");
        // remove dead code -> saves 45256
        if (_tier > 3) {
            whitelist[_userAddrs] = 3;
        } else {
            whitelist[_userAddrs] = _tier;
        }

        // remove dead code -> saves 36834
        // uint256 wasLastAddedOdd = wasLastOdd;
        // if (wasLastAddedOdd == 1) {
        //     wasLastOdd = 0;
        //     isOddWhitelistUser[_userAddrs] = wasLastAddedOdd;
        // } else if (wasLastAddedOdd == 0) {
        //     wasLastOdd = 1;
        //     isOddWhitelistUser[_userAddrs] = wasLastAddedOdd;
        // } else {
        //     revert("Contract hacked, imposible, call help");
        // }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public checkIfWhiteListed(msg.sender) {
        // address senderOfTx = msg.sender; // saves 3400
        whiteListStruct[msg.sender] = ImportantStruct(
            _amount,
            true,
            msg.sender
        );

        require(
            balances[msg.sender] >= _amount,
            "Gas Contract: Insufficient Balance"
        );
        require(_amount > 3, "Gas Contract: Insufficient Amount");
        uint256 whitelistBalance = whitelist[msg.sender]; // saves 1807
        balances[msg.sender] =
            balances[msg.sender] -
            _amount +
            whitelistBalance; // saves 6000
        balances[_recipient] =
            balances[_recipient] +
            _amount -
            whitelistBalance; // saves 6606

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(
        address sender
    ) public view returns (bool, uint256) {
        return (
            whiteListStruct[sender].paymentStatus,
            whiteListStruct[sender].amount
        );
    }

    // dead code -> saves 19020
    // receive() external payable {
    //     payable(msg.sender).transfer(msg.value);
    // }

    // fallback() external payable {
    //     payable(msg.sender).transfer(msg.value);
    // }
}
