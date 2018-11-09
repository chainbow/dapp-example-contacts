pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

contract Contact {
    
    address owner;
    uint contractId;
    contact[] contacts;
    
    struct contact {
        uint id;
        string name;
        string contactAddress;
        string tel;
    }
    
    constructor () public {
        owner = msg.sender;
        contractId = 0;
    }
    
    function addContact (string name, string contactAddress, string tel) public {
        contractId += 1;
        contacts.push(contact(contractId, name, contactAddress, tel));
    }
    
    function updateContact (uint id, string name, string contactAddress, string tel) public {
        if (id > contacts.length) return;
        
        for (uint i = 0; i < contacts.length; i++) {
            if (contacts[i].id == id) {
                contacts[i].name = name;
                contacts[i].contactAddress = contactAddress;
                contacts[i].tel = tel;
                break;
            }
        }
    }
    
    function deleteContact (uint id) public {
        if (id > contacts.length) return;
        
        for (uint i = 0; i < contacts.length; i++) {
            if (contacts[i].id == id) {
                delete contacts[i];
                contacts[i] = contacts[contacts.length - 1];
                delete contacts[contacts.length - 1];
                contacts.length--;
            }
        }
    }
    
    function getContactList () public constant returns (contact[]) {
        return contacts;
    }
    
}
