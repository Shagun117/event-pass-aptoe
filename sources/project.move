module MyModule::EventPassNFT {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::string::{Self, String};
    use std::vector;
    
    /// Struct representing an Event Pass NFT
    struct EventPass has store, key {
        event_name: String,      // Name of the event
        ticket_price: u64,       // Price of the ticket in APT
        max_tickets: u64,        // Maximum number of tickets available
        sold_tickets: u64,       // Number of tickets sold
        is_active: bool,         // Whether ticket sales are active
    }
    
    /// Struct representing a user's ticket
    struct UserTicket has store, key {
        event_name: String,      // Event name for the ticket
        ticket_id: u64,          // Unique ticket ID
        is_valid: bool,          // Whether the ticket is valid for entry
    }
    
    /// Error codes
    const E_EVENT_NOT_FOUND: u64 = 1;
    const E_INSUFFICIENT_PAYMENT: u64 = 2;
    const E_TICKETS_SOLD_OUT: u64 = 3;
    const E_EVENT_INACTIVE: u64 = 4;
    const E_TICKET_NOT_FOUND: u64 = 5;
    
    /// Function to create a new event with ticket sales
    public fun create_event(
        organizer: &signer, 
        event_name: String, 
        ticket_price: u64, 
        max_tickets: u64
    ) {
        let event_pass = EventPass {
            event_name,
            ticket_price,
            max_tickets,
            sold_tickets: 0,
            is_active: true,
        };
        move_to(organizer, event_pass);
    }
    
    /// Function for users to buy event tickets (mint NFT)
    public fun buy_ticket(
        buyer: &signer, 
        organizer_address: address, 
        payment_amount: u64
    ) acquires EventPass {
        let event = borrow_global_mut<EventPass>(organizer_address);
        
        // Check if event is active
        assert!(event.is_active, E_EVENT_INACTIVE);
        
        // Check if tickets are available
        assert!(event.sold_tickets < event.max_tickets, E_TICKETS_SOLD_OUT);
        
        // Check if payment is sufficient
        assert!(payment_amount >= event.ticket_price, E_INSUFFICIENT_PAYMENT);
        
        // Process payment
        let payment = coin::withdraw<AptosCoin>(buyer, payment_amount);
        coin::deposit<AptosCoin>(organizer_address, payment);
        
        // Create and mint ticket NFT
        let ticket_id = event.sold_tickets + 1;
        let user_ticket = UserTicket {
            event_name: event.event_name,
            ticket_id,
            is_valid: true,
        };
        
        // Update sold tickets count
        event.sold_tickets = event.sold_tickets + 1;
        
        // Transfer ticket to buyer
        move_to(buyer, user_ticket);
    }
}