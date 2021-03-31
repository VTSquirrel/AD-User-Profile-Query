# AD-User-Profile-Query
Scan all users that have logged into specified target devices and query Active Directory to retrieve profile information. 
This is useful for troubleshooting to identify which users have logged into a particular machine.

## Usage
```
.\ADUserProfileQuery.ps1 -Targets DEVICE1, DEVICE2


ComputerName DisplayName  EmailAddress      OfficePhone  Title   Department                 
------------ -----------  ------------      -----------  -----   ----------                 
DEVICE1      Example User user@example.com  123-456-7890 Manager Dept. Name
...etc                                                                                           
```
