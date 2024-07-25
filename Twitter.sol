// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Twitter {
    struct Tweet {
        uint256 ID;
        address author;
        string content;
        uint256 timestamp;
    }

    struct Message {
        uint256 ID;
        address sender;
        address receiver;
        string content;
        uint256 timestamp;
    }

    mapping(uint256 => Tweet) public tweets;
    mapping(address => uint256[]) public tweetsof;
    mapping(address => mapping(address => Message[])) public conversations;
    mapping(address => mapping(address => bool)) public operators;
    mapping(address => address[]) public following;

    uint256 public tweetCounter;

    modifier isOperatorAuthorized(address _from) {
        require(operators[_from][msg.sender], "Not Authorized");
        _;
    }

    // Functions:
    // Internal function to handle the tweeting logic--
    function _tweet(address _from, string memory _content) internal {
        tweets[tweetCounter] = Tweet(
            tweetCounter,
            _from,
            _content,
            block.timestamp
        );
        tweetsof[_from].push(tweetCounter);
        tweetCounter++;
    }

    // Internal function to handle messaging logic.
    function _sendMessage(
        address _from,
        address _to,
        string memory _content
    ) internal {
        uint256 messageId = conversations[_from][_to].length;
        conversations[_from][_to].push(
            Message(messageId, _from, _to, _content, block.timestamp)
        );
    }

    // Allows a user to post a tweet--
    function tweet(string memory _content) public {
        _tweet(msg.sender, _content);
    }

    // Allows an operator to post a tweet on behalf of a user--
    function tweet(address _from, string memory _content)
        public
        isOperatorAuthorized(_from)
    {
        _tweet(_from, _content);
    }

    // Allows a user to send a message--
    function sendMessage(string memory _content, address _to) public {
        _sendMessage(msg.sender, _to, _content);
    }

    // Allows an operator to send a message on behalf of a user--
    function sendMessage(
        address _from,
        address _to,
        string memory _content
    ) public isOperatorAuthorized(_from) {
        _sendMessage(_from, _to, _content);
    }

    // Allows a user to follow another user--
    function follow(address _followed) public {
        following[msg.sender].push(_followed);
    }

    // Allows a user to authorize an operator--
    function allow(address _operator) public {
        operators[msg.sender][_operator] = true;
    }

    // Allows a user to revoke an operator's authorization--
    function disallow(address _operator) public {
        operators[msg.sender][_operator] = false;
    }

    // Returns the latest tweets across all users--
    function getLatestTweets(uint256 count)
        public
        view
        returns (Tweet[] memory)
    {
        Tweet[] memory latestTweets = new Tweet[](count);
        for (uint256 i = 0; i < count && i < tweetCounter; i++) {
            latestTweets[i] = tweets[tweetCounter - 1 - i];
        }
        return latestTweets;
    }

    // Returns the latest tweets of a specific user--
    function getLatestTweetsOf(address user, uint256 count)
        public
        view
        returns (Tweet[] memory)
    {
        uint256[] storage userTweets = tweetsof[user];
        uint256 tweetCount = userTweets.length;
        Tweet[] memory latestTweets = new Tweet[](count);
        for (uint256 i = 0; i < count && i < tweetCount; i++) {
            latestTweets[i] = tweets[userTweets[tweetCounter - 1 - i]];
        }
        return latestTweets;
    }
}
