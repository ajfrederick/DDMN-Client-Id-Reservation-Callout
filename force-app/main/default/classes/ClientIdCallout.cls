/**
* @name ClientIdCallout
*
* @description this calss was built to help replace wv6_getNextavailableClientIdentifier and wv6_reserveClientIdentifier. 
* These callouts makes a callout directly to DDMI. It skips the call to the reverse proxy at DDMN. 
*
* @author Creed Interactive (Andrew Frederick) 2/24/22
*/
public without sharing class ClientIdCallout {

/**
* FIELDS
*/

    private static AccessTokenResponse accessTokenResponse {
        get {
            
            if( accessTokenResponse == null || accessTokenResponse.isExpired() ){
                getAccessToken();
            }

            return accessTokenResponse;
        }
        set;
    }

    // client credentials
    private static api_credential__mdt credential;

    public static Boolean isDev;

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

        try {
            
            isDev = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;

        } catch( Exception e ){
            creedint.CreedExceptionHandler handler = new creedint.CreedExceptionHandler(e);
            handler.handle();
        }
    }

    private static final String URL_ENCODED_CONTENT_TYPE = 'application/x-www-form-urlencoded';
    private static final String JSON_CONTENT_TYPE = 'application/json;charset=UTF-8';

    private static final String GRANT_TYPE = 'client_credentials';
    private static final String CONTENT_LENGTH = '174';
    
/**
* ACTION METHODS
*/

    /**
     * @name getAccessToken
     * @description gets the access token for the get next available client id and reserve client id callouts
     * @param none
     * @return none
     */
    private static void getAccessToken(){

        if( credential == null || getClientId() == null || getClientSecret() == null ){
            throw new InvocableException('Client credentials not found for access token.');
        }

        try {

            AccessTokenHttpHandler handler = new AccessTokenHttpHandler();
            handler.send( getAccessTokenRequest() );
            
            accessTokenResponse = handler.getTokenReponse();

        } catch( Exception e ){
            creedint.CreedExceptionHandler handler = new creedint.CreedExceptionHandler(e);
            handler.handle();
        }
    }

/**
* UTILITY METHODS
*/  

    /**
     * @name getAccessTokenRequest
     * @description eturns the request object fully loaded with what is required for the access token request
     * @param none
     * @return HttpRequest
     */
    private static HttpRequest getAccessTokenRequest(){
        String requestBody = 'grant_type=' + EncodingUtil.urlEncode( GRANT_TYPE, 'UTF-8') + '&';
        requestBody += 'client_id=' + EncodingUtil.urlEncode( getClientId(), 'UTF-8') + '&';
        requestBody += 'client_secret=' + EncodingUtil.urlEncode( getClientSecret(), 'UTF-8') + '&';
        requestBody += 'scope=' + EncodingUtil.urlEncode( getScope(), 'UTF-8');

        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type', URL_ENCODED_CONTENT_TYPE);
        request.setHeader('Content-Length', CONTENT_LENGTH);
        request.setBody( requestBody );

        return request;
    }

    /**
     * @name getClientIdRequest
     * @description returns the request object fully loaded with what is required for the base request
     * @param none
     * @return HttpRequest
     */
    public static HttpRequest getClientIdRequest(){

        if( !hasAccessToken() ){
            throw new InvocableException('Access token not retrieved');
        }

        String csrfToken = getCSRFToken();

        HttpRequest request = new HttpRequest();
        request.setHeader( 'Content-Type', JSON_CONTENT_TYPE );
        request.setHeader( 'access_token', accessTokenResponse.accessToken );
        request.setHeader( 'client_id', getClientId() );
        request.setHeader( 'X_CSRF_TOKEN', csrfToken );
        request.setHeader( 'Cookie', 'CSRF_TOKEN=' + csrfToken );

        return request;
    }

    /**
     * @name getAccessTokenURL
     * @description checks environment then returns the DDMI Idp URL from the credential gathered above
     * @param none
     * @return String
     */
    private static String getAccessTokenURL(){
        return isDev ? credential.Access_Token_URL_Dev__c : credential.Access_Token_URL__c;
    }

    /**
     * @name getRequestURL
     * @description checks environment then returns the final request base URL from the credential gathered above
     * @param none
     * @return String
     */
    public static String getRequestURL(){
        return isDev ? credential.Final_Request_URL_Dev__c : credential.Final_Request_URL__c;
    }

    /**
     * @name getClientId
     * @description checks environment then returns the DDMI Idp Client Id (nothing to do the client Id request) from the credential gathered above
     * @param none
     * @return String
     */
    private static String getClientId(){
        return isDev ? credential.Client_Id_Dev__c : credential.Client_Id__c;
    }

    /**
     * @name getClientSecret
     * @description checks environment then returns the DDMI Idp Client Secret from the credential gathered above
     * @param none
     * @return String
     */
    private static String getClientSecret(){
        return isDev ? credential.Client_Secret_Dev__c : credential.Client_Secret__c;
    }

    /**
     * @name getScope
     * @description checks environment then returns the DDMI Idp scope which dictates what we are authorized for. from the credential gathered above
     * @param none
     * @return String
     */
    private static String getScope(){
        return credential.Scope__c;
    }

    /**
     * @name hasAccessToken
     * @description checks whether or not we have an access token or that is has expired
     * @param none
     * @return Boolean
     */
    public static Boolean hasAccessToken(){
        return accessTokenResponse != null && accessTokenResponse.hasToken() && !accessTokenResponse.isExpired();
    }

    /**
     * @name getCSRFToken
     * @description generates a CSRF token of a specific format. We generate this for the CSRF token and XCSRF token. They must match
     * @param none
     * @return String
     */
    public static String getCSRFToken(){
        String token = getRandomNumberString(7) + '-';
        token += getRandomAlphaNumbericString(8) + '-';
        token += getRandomAlphaNumbericString(4) + '-';
        token += getRandomAlphaNumbericString(4) + '-';
        token += getRandomAlphaNumbericString(4) + '-';
        token += getRandomAlphaNumbericString(12);
        
        return token;
    }

    /**
     * @name getRandomNumberString
     * @description generates a random number string for the CSRF Token
     * @param Integer count
     * @return String
     */
    private static String getRandomNumberString( Integer count ){
        String randomNumber = '';

        for( Integer i = 0; i < count; i++ ){
            randomNumber += String.valueOf( getRandom0thru9() );
        }

        // the ddmi api will mark csrf token as invalid if the first 8 digits are not within the window of these to integer values
        if( Integer.valueOf(randomNumber) < 1605340 || Integer.valueOf(randomNumber) > 7857652 ){
            randomNumber = getRandomNumberString(7);
        }

        return randomNumber;
    }

    /**
     * @name getRandomAlphaNumbericString
     * @description generates a random alpha numeric string for the CSRF Token
     * @param Integer count
     * @return String
     */
    private static String getRandomAlphaNumbericString( Integer count ){
        return EncodingUtil.convertToHex(Crypto.generateAesKey(128)).substring(0, count);
    }

    /**
     * @name getRandom0thru9
     * @description returns a random number 0 through 9 for the CSRF Token
     * @param none
     * @return String
     */
    private static Integer getRandom0thru9(){
        return (Integer) Math.floor( Math.random() * 10 );
    }

/**
* CLASSES
*/

    public class AccessTokenHttpHandler extends HttpHandler {

        private final String ACCESS_TOKEN_KEY = 'access_token';
        private final String EXPIRATION_KEY = 'expires_in';

        public override String getEndpoint(){
            return getAccessTokenURL();
        }

        public override String getMethod(){
            return 'POST';
        }

        public AccessTokenResponse getTokenReponse(){
            Map<String, Object> deserialized = (Map<String, Object>) JSON.deserializeUntyped( getReponseBody() );

            AccessTokenResponse response = new AccessTokenResponse();
            response.accessToken = getAccessToken( deserialized );
            response.expiration = getExpiration( deserialized );

            return response;
        } 

        private String getAccessToken( Map<String, Object> deserialized ){
            return deserialized.containsKey(ACCESS_TOKEN_KEY) ? (String) deserialized.get(ACCESS_TOKEN_KEY) : '';
        }

        private DateTime getExpiration( Map<String, Object> deserialized ){
            return deserialized.containsKey(EXPIRATION_KEY) ? getDateTime( deserialized ) : null;
        }

        private DateTime getDateTime( Map<String, Object> deserialized ){
            Integer seconds = (Integer) deserialized.get(EXPIRATION_KEY) - 600; // expire in 1 hour but let's remove 10 minutes just for "travel safety"

            return DateTime.now().addSeconds(seconds);
        }
    }

    public class AccessTokenResponse {

        public String accessToken {get;set;}
        public DateTime expiration {get;set;}

        public Boolean hasToken(){
            return !String.isEmpty( accessToken );
        }

        public Boolean isExpired(){
            return expiration != null ? DateTime.now() > expiration : false; // false to avoid endless callout loop if expiration is null
        }
    }
    
/**
* EXCEPTION CLASSES
*/

    class InvocableException extends Exception {}

}