pragma solidity ^ 0.4.25;
pragma experimental ABIEncoderV2;

contract Contact {

  struct contact {
    uint id;
    string name;
    string contactAddress;
    string tel;
  }

  contact[] contacts;
  uint id;

  function Contract() {
    id = 0;
  }

  function addContact(string name, string contactAddress, string tel) {
    id += 1;
    contacts.push(contact(id, name, contactAddress, tel));
  }

  function updateContact(uint id, string name, string contactAddress, string tel) {
    for (uint i = 0; i < contacts.length; i++) {
      if (contacts[i].id == id) {
        contacts[i].name = name;
        contacts[i].contactAddress = contactAddress;
        contacts[i].tel = tel;
        break;
      }
    }
  }

  function deleteContact(uint id) {
    if (contacts.length == 0) {
      revert("No contact yet!");
    }

    for (uint i = 0; i < contacts.length; i++) {
      if (contacts[i].id == id) {
        delete contacts[i];
        contacts[i] = contacts[contacts.length - 1];
        delete contacts[contacts.length - 1];
      }
    }
  }

  function getContactList() constant returns(contact[]) {
    return contacts;
  }

}
