// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {

	/*
	 * On-chain Variable Storage. The "state".
	 * Compiler creates getter functions for public state variables to allow reads by other contracts.
	 */
	address public owner;
	uint public skuCount;
 
	enum State { ForSale, Sold, Shipped, Received }
	struct Item {
		string name;
		uint sku; 
		uint price;
		State state;
		address payable seller;
		address payable buyer;
	}
	mapping (uint => Item) public items;


	/* Constructor is special function which runs once during contract deployment. */
	constructor() {
		owner = msg.sender;
		skuCount = 0;
	}

	/*
	 * Broadcast various info to log for important actions or steps taken. 
	 * Logs are for use by external listeners (not other contracts). 
	 */
	event LogForSale(uint sku);
	event LogSold(uint sku);
	event LogShipped(uint sku);
	event LogReceived(uint sku);

	/* 
	 * Modifier is called in the function spec.
	 * Modifiers run code before or after a function runs.
	 * When modifier actually runs depends on "_;" positioning.
	 */
	modifier isownerModifier { // This modifier is not actually used.
		require(msg.sender == owner, "Must be contract owner."); 
		_; // the calling function runs now.
	}
	modifier verifyCallerModifier (address _checkAddress) {
		require (msg.sender == _checkAddress, "Not the correct calling address."); 
		_; // the calling function runs now.
	}
	modifier paidEnoughModifier (uint _price) { 
		require(msg.value >= _price, "Must pay at least item price."); 
		_; // the calling function runs now.
	}
	modifier refundOverageModifier (uint _sku) {
		uint price = items[_sku].price;
		uint amountToRefund = msg.value - price; // presumes sent value > price.
		_; // the calling function runs now.
		items[_sku].buyer.transfer(amountToRefund);
	}
	modifier forSaleModifier (uint _sku) {
		require (items[_sku].state == State.ForSale, "Item must be for sale before purchasing the item.");
		_; // the calling function runs now.
	}
	modifier soldModifier (uint _sku) {
		require (items[_sku].state == State.Sold, "Item must be sold before shipping the item.");
		_; // the calling function runs now.		
	}
	modifier shippedModifier (uint _sku) {
		require (items[_sku].state == State.Shipped, "Item must be shipped before receiving the item.");
		_; // the calling function runs now.		
	}
	modifier receivedModifier (uint _sku) {
		require (items[_sku].state == State.Received, "Item must be received before xxxxx the item.");
		_; // the calling function runs now.		
	}


	function addItem(string memory _name, uint _price) public returns (bool) {
		require(_price >= 0, "Item price may not be negative.");
		// maybe disallow item name re-use ??? would require iterate over all items to search for existing names.
		// skuCount += 1; // in real life likely want to increment at top of this function.
		items[skuCount] = Item({ 
			name:   _name, 
			sku:    skuCount, 
			price:  _price, 
			state:  State.ForSale, // presume new item is "for sale".
			seller: payable(msg.sender), 
			buyer:  payable(address(0)) 
		});
		emit LogForSale(skuCount);
		skuCount += 1; // increment here at bottom of function just to pass automated tests.
		return true; // seems would want to return the new item index as uint instead of meaningless bool.
	}

	function buyItem(uint _sku) public payable forSaleModifier(_sku) paidEnoughModifier(items[_sku].price) refundOverageModifier(_sku) {
		items[_sku].seller.transfer(items[_sku].price); // transfer payment to seller.
		items[_sku].buyer = payable(msg.sender);
		items[_sku].state = State.Sold;
		emit LogSold(_sku);
	}

	function shipItem(uint _sku) public soldModifier(_sku) verifyCallerModifier(items[_sku].seller) {
		items[_sku].state = State.Shipped;
		emit LogShipped(_sku);
	}

	function receiveItem(uint _sku) verifyCallerModifier(items[_sku].buyer) public shippedModifier(_sku) {
		items[_sku].state = State.Received;
		emit LogReceived(_sku);
	}

  // Uncomment the following code block. it is needed to run tests
   function fetchItem(uint _sku) public view
     returns (string memory name, uint sku, uint price, uint state, address seller, address buyer)
   {
     name = items[_sku].name;
     sku = items[_sku].sku; 
     price = items[_sku].price;
     state = uint(items[_sku].state);
     seller = items[_sku].seller; 
     buyer = items[_sku].buyer; 
     return (name, sku, price, state, seller, buyer); 
   } 
}
