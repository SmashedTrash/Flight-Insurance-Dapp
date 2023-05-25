pragma solidity >=0.4.24 <0.6.0;



import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
contract FlightSuretyApp {
    using SafeMath for uint256; 
    using SafeMath for uint256;

    FlightSuretyData flightSuretyData;

    address private contractOwner; 
    bool private operational = true; 
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;
    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
    }
    mapping(bytes32 => Flight) private flights;

    uint256 constant M = 4; 
    bool private vote_status = false;
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 2;

    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester; 
        bool isOpen; 
        mapping(uint8 => address[]) responses; 
    }

    mapping(bytes32 => ResponseInfo) private oracleResponses;

    event RegisterAirline(address account);
    event PurchaseInsurance(address airline, address sender, uint256 amount);
    event CreditInsurees(address airline, address passenger, uint256 credit);
    event FundedLines(address funded, uint256 value);
    event Withdraw(address sender, uint256 amount);
   
        uint8 index,
        address airline,
        string flight,
        uint256 timestamp
    );
    event SubmitOracleResponse(
        uint8 indexes,
        address airline,
        string flight,
        uint256 timestamp,
        uint8 statusCode
    );
    event FlightStatusInfo(
        address airline,
        string flight,
        uint256 timestamp,
        uint8 status
    );
    event OracleReport(
        address airline,
        string flight,
        uint256 timestamp,
        uint8 status
    );
    /**
     * @dev 
     */
    modifier requireIsOperational() {
        require(operational, "Contract is currently not operational");
        _;
    }

    /**
     * @dev 
     */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

     * @dev Contract constructor
     *
     */
    constructor(address dataContract) public {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(dataContract);
        flightSuretyData.registerAirline(contractOwner, true);

        emit RegisterAirline(contractOwner);
    }

    function isOperational() public view returns (bool) {
        return operational;
    }

    /**
     * @dev 
     */

    function registerAirline(address airline)
        external
        requireIsOperational
        returns (bool, bool)
    {
        require(airline != address(0), "'account' must be a valid address.");
        require(
            !flightSuretyData.getAirlineRegistrationStatus(airline),
            "Airline is already registered"
        );
        require(
            flightSuretyData.getAirlineOperatingStatus(msg.sender),
            "Caller airline is not operational"
        );

        uint256 multicall_Length = flightSuretyData.multiCallsLength();

        if (multicall_Length < M) {
            flightSuretyData.registerAirline(airline, false);
            emit RegisterAirline(airline);
            return (true, false); 
        } else {
            if (vote_status) {
                uint256 voteCount = flightSuretyData.getVoteCounter(airline);

                if (voteCount >= multicall_Length / 2) {
        
                    flightSuretyData.registerAirline(airline, false);

                    vote_status = false;
                    flightSuretyData.resetVoteCounter(airline);

                    emit RegisterAirline(airline);
                    return (true, true);
                } else {
                    flightSuretyData.resetVoteCounter(airline);
                    return (false, true);
                }
            } else {
                return (false, false);
            }
        }
    }

    /**
     * @dev 
     *
     */

    function approveAirlineRegistration(address airline, bool airline_vote)
        public
        requireIsOperational
    {
        require(
            !flightSuretyData.getAirlineRegistrationStatus(airline),
            "airline already registered"
        );
        require(
            flightSuretyData.getAirlineOperatingStatus(msg.sender),
            "airline not operational"
        );
        if (airline_vote == true) {
            bool isDuplicate = false;
            uint256 incrementVote = 1;
            isDuplicate = flightSuretyData.getVoterStatus(msg.sender);

            require(!isDuplicate, "Caller has already voted.");
            flightSuretyData.addVoters(msg.sender);
            flightSuretyData.addVoterCounter(airline, incrementVote);
        }
        vote_status = true;
    }

    /**
     * @dev 
     *
     */
    function fund() public payable requireIsOperational {
        
        require(msg.value == 10 ether, "Ether should be 10");
        require(
            !flightSuretyData.getAirlineOperatingStatus(msg.sender),
            "Airline is already funded"
        );

        flightSuretyData.fundAirline(msg.sender, msg.value);

        flightSuretyData.setAirlineOperatingStatus(msg.sender, true);

        emit FundedLines(msg.sender, msg.value);
    }

    /**
     * @dev 
     *
     */
    function buy(address airline) external payable requireIsOperational {
        require(
            flightSuretyData.getAirlineOperatingStatus(airline),
            "Airline you are buying insurance from should be operational"
        );
        require(
            (msg.value > 0 ether) && (msg.value <= 1 ether),
            "You can not buy insurance of more than 1 ether or less than 0 ether"
        );
        flightSuretyData.registerInsurance(airline, msg.sender, msg.value);
        emit PurchaseInsurance(airline, msg.sender, msg.value);
    }

    function getPassenger_CreditedAmount() external returns (uint256) {
        uint256 credit = flightSuretyData.getPassengerCredit(msg.sender);
        return credit;
    }
    /**
     @dev 
     */
    function withdraw() external requireIsOperational {
        require(
            flightSuretyData.getPassengerCredit(msg.sender) > 0,
            "No balance to withdraw"
        );

        uint256 withdraw_value = flightSuretyData.withdraw(msg.sender);
        msg.sender.transfer(withdraw_value);

        emit Withdraw(msg.sender, withdraw_value);
    }
    /**
     * @dev 
     */
    function processFlightStatus(
        address airline,
        string flight,
        uint256 timestamp,
        uint8 statusCode
    ) public {
        address passenger;
        uint256 amountPaid;
        (passenger, amountPaid) = flightSuretyData.getInsuredPassenger_amount(
            airline
        );
        require(
            (passenger != address(0)) && (airline != address(0)),
            "'accounts' must be  valid address."
        );
        require(amountPaid > 0, "Passenger is not insured");

        // Only credit if flight delay is airline fault (airline late and late due to technical)
        if (
            (statusCode == STATUS_CODE_LATE_AIRLINE) ||
            (statusCode == STATUS_CODE_LATE_TECHNICAL)
        ) {
            uint256 credit = amountPaid.mul(3).div(2);

            flightSuretyData.creditInsurees(airline, passenger, credit);
            emit CreditInsurees(airline, passenger, credit);
        }
    }

    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(
        address airline,
        string flight,
        uint256 timestamp
    ) external requireIsOperational {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key =
            keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
            requester: msg.sender,
            isOpen: true
        });

        emit OracleRequest(index, airline, flight, timestamp);
    }

    /* ORACLE MANAGEMENT*/
    function triggerOracleResponse(
        uint8 indexes,
        address airline,
        string flight,
        uint256 timestamp,
        uint8 statusCode
    ) external {
        emit SubmitOracleResponse(
            indexes,
            airline,
            flight,
            timestamp,
            statusCode
        );
    }
    function getResistration_fee() external pure returns (uint256) {
        return REGISTRATION_FEE;
    }

    // Register an oracle with the contract
    function registerOracle() external payable {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({isRegistered: true, indexes: indexes});
    }

    function getMyIndexes() external view returns (uint8[3] memory) {
        require(
            oracles[msg.sender].isRegistered,
            "Not registered as an oracle"
        );

        return oracles[msg.sender].indexes;
    }

    function submitOracleResponse(
        uint8 index,
        address airline,
        string flight,
        uint256 timestamp,
        uint8 statusCode
    ) external requireIsOperational {
        require(
            (oracles[msg.sender].indexes[0] == index) ||
                (oracles[msg.sender].indexes[1] == index) ||
                (oracles[msg.sender].indexes[2] == index),
            "Index does not match oracle request"
        );

        bytes32 key =
            keccak256(abi.encodePacked(index, airline, flight, timestamp));
        require(
            oracleResponses[key].isOpen,
            "Flight or timestamp do not match oracle request"
        );

        oracleResponses[key].responses[statusCode].push(msg.sender);

        emit OracleReport(airline, flight, timestamp, statusCode);
        if (
            oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES
        ) {
            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }

    function getFlightKey(
        address airline,
        string flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    function generateIndexes(address account) internal returns (uint8[3]) {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);

        indexes[1] = indexes[0];
        while (indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while ((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }
    function getRandomIndex(address account) internal returns (uint8) {
        uint8 maxValue = 10;

        uint8 random =
            uint8(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            blockhash(block.number - nonce++),
                            account
                        )
                    )
                ) % maxValue
            );

        if (nonce > 250) {
            nonce = 0;
        }

        return random;
    }
    /**
      @dev 
     */

    function() external payable {
        fund();
    }
}

contract FlightSuretyData {
    function registerAirline(address account, bool isOperational) external;

    function multiCallsLength() external returns (uint256);

    function getAirlineOperatingStatus(address account) external returns (bool);

    function setAirlineOperatingStatus(address account, bool status) external;

    function registerInsurance(
        address airline,
        address passenger,
        uint256 amount
    ) external;

    function creditInsurees(
        address airline,
        address passenger,
        uint256 amount
    ) external;

    function getInsuredPassenger_amount(address airline)
        external
        returns (address, uint256);

    function getPassengerCredit(address passenger) external returns (uint256);

    function getAirlineRegistrationStatus(address account)
        external
        returns (bool);

    function fundAirline(address airline, uint256 amount) external;

    function getAirlineFunding(address airline) external returns (uint256);

    function withdraw(address passenger) external returns (uint256);

    function getVoteCounter(address account) external returns (uint256);

    function setVoteCounter(address account, uint256 vote) external;

    function getVoterStatus(address voter) external returns (bool);

    function addVoterCounter(address airline, uint256 count) external;

    function resetVoteCounter(address account) external;

    function addVoters(address voter) external;
}
