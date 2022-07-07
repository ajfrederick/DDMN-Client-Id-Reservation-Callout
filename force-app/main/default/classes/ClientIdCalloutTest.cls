/**
 * @name ClientIdCalloutTest
 * @description Tests Client Id Callout functionality
 * 
 * @author Creed Interactive (Andrew Frederick) July 2022
 */
@IsTest(SeeAllData=true)
public with sharing class ClientIdCalloutTest {

/**
* FIELDS
*/

    // client credentials
    private static api_credential__mdt credential;

    /**
    * Static block to set credential and isDev variables;
    */
    static {

        try {
            
            credential = api_credential__mdt.getInstance('DDMI_Client_Id_Credentials');

        } catch( Exception e ){
            creedint.CreedExceptionHandler handler = new creedint.CreedExceptionHandler(e);
            handler.handle();
        }
    }

    public static final String ACCESS_TOKEN = 'AccessTokenValue';
    public static final String CLIENT_ID = '123456';
    public static final String RESERVE_SUCCESS_MESSAGE = 'Client Id Reserved!';
   
/**
* TEST METHODS
*/

    @IsTest
    public static void testGetNext(){

        ClientIdTestMultiMock mock = new ClientIdTestMultiMock();
        mock.addMock( getAccessTokenURL(), new ClientIdAccessTokenMock() );
        mock.addMock( getRequestURL() + '/DDMN/nextAvailableClientIdentifier', new ClientIdGetNextMock() );
        mock.addMock( getRequestURL() + '/reservations', new ClientIdReserveMock() );

        Test.setMock( HttpCalloutMock.class, mock );
        
        Test.startTest();


            // TEST GET NEXT
            ClientIdCalloutGetNext.ClientIdGetNextRequest getNextRequest = new ClientIdCalloutGetNext.ClientIdGetNextRequest();
            getNextRequest.planAcronym = 'DDMN';

            ClientIdCalloutGetNext.ClientIdGetNextRequest[] getNextRequests = new ClientIdCalloutGetNext.ClientIdGetNextRequest[]{};
            getNextRequests.add( getNextRequest );

            ClientIdCalloutGetNext.ClientIdGetNextResponse[] getNextResponses = ClientIdCalloutGetNext.getNext( getNextRequests );


            // TEST RESERVE
            ClientIdCalloutReserve.ClientIdReserveRequest reserveRequest = new ClientIdCalloutReserve.ClientIdReserveRequest();
            reserveRequest.planAcronym = 'DDMN';
            reserveRequest.clientSpecifiedIdentifier = getNextResponses[0].nextAvailableClientId;
            reserveRequest.clientName = 'Test Client for DDMN Salesforce';
            reserveRequest.clientStartDate = 'July 1, 2022';
            reserveRequest.reservedBy = 'Andrew Frederick';

            ClientIdCalloutReserve.ClientIdReserveRequest[] reserveRequests = new ClientIdCalloutReserve.ClientIdReserveRequest[]{};
            reserveRequests.add(reserveRequest);

            ClientIdCalloutReserve.ClientIdReserveResponse[] reserveResponses = ClientIdCalloutReserve.reserve( reserveRequests );

        Test.stopTest();

        System.assertEquals( CLIENT_ID, getNextResponses[0].nextAvailableClientId );
        System.assertEquals( RESERVE_SUCCESS_MESSAGE, reserveResponses[0].message );
    }

    /**
     * @name getAccessTokenURL
     * @description checks environment then returns the DDMI Idp URL from the credential gathered above
     * @param none
     * @return String
     */
    private static String getAccessTokenURL(){
        return ClientIdCallout.isDev ? credential.Access_Token_URL_Dev__c : credential.Access_Token_URL__c;
    }

    /**
     * @name getRequestURL
     * @description checks environment then returns the final request base URL from the credential gathered above
     * @param none
     * @return String
     */
    private static String getRequestURL(){
        return ClientIdCallout.isDev ? credential.Final_Request_URL_Dev__c : credential.Final_Request_URL__c;
    }
}
