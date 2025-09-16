/**
 * File: PDFService.cfc
 * Author: Samuel Knowlton <sam@inleague.io>
 * Date: January 3, 2020
 * Description: Wrapper to send and receive content to wkhtmltopdf container, based on the inLeague version of https://github.com/MotorsportReg/docker-wkhtmltopdf-service (https://gitlab.inleague.io/inLeague/wkhtmltopdf)
 */

component {

    property name="wirebox" inject="wirebox";
    property name="pdfsettings" inject="coldbox:modulesettings:wkhtmltopdf";

    boolean function isLucee(){
		return structKeyExists( server, "lucee" );
	}

    private string function getPDFURL() {
        return ( pdfsettings.pdfsecure ? 'https' : 'http' ) & '://' & pdfsettings.pdfhost & ':' & pdfsettings.pdfport; 
    }

    /**
     * @hint Checks the HyperResponse object for a timeout status code
     */

    private boolean function isTimeoutResponse( required hyper.models.HyperResponse response ) {
        var code = int( arguments.response.getStatusCode() );
        return ( code == 408 || code == 504 );
    }

    
    /**
     * @hint Shared POST to the wkhtmltopdf service with retry + timeout.
     * @endpoint: URI like "/pdf"
     * @body: struct sent as JSON
     * @retries: number of retries on timeout (0..3)
     * @timeout: request timeout (seconds)
     */


    private any function sendToPDFService(
        required string endpoint = getPDFURL(),
        required struct body,
        numeric retries = 0,
        numeric timeout = 10
    ) {
        var maxRetries = min( 3, abs( int( arguments.retries ) ) );

        // Total attempts = maxRetries + 1 (the initial try + N retries)
        for ( var attempt = 0; attempt <= maxRetries; attempt++ ) {
            try {
                var response = wirebox.getInstance( "HyperBuilder@hyper" )
                    .setBaseURL( getPDFURL() )
                    .setURL( arguments.endpoint )
                    .setMethod( "POST" )
                    .asJson()
                    .setTimeout( int( arguments.timeout ) ) // seconds
                    .allowErrors()                                // don't throw on 4xx/5xx
                    .setBody( arguments.body )
                    .send();

                if ( isTimeoutResponse( response ) && attempt < maxRetries ) {
                    sleep( 50 * ( attempt + 1 ) ); // 50ms, 100ms, 150ms...
                    continue;                        // try again
                }

                // Defer to your existing handler (throws if needed)
                return handleResponseObject( response = response );

            } catch ( any e ) {
                // Non-HTTP/transport exceptions: bubble up
                rethrow;
            }
        }
    }


    /**
     * toPDF
     * @hint A simple wrapper for a single input stream
     * @html String to convert to PDF
     * @options Struct for wkhtmltopdf options
     * @output desired output from wkhtmltopdf: pdf, png, or jpg
     * @retries number of retries on timeout (0 default, recommend no more than 2 or 3)
     * @timeout timeout in seconds for the http call to wkhtmltopdf
    */

    public function toPDF( required string content, struct options = {}, string output = 'pdf', retries = 0, timeout = 10 ) {
        
        var isURL = isValid( "url", arguments.content );

        var contentType = isURL ? "url" : "content";

        var pdfRequest = {
            "options" : arguments.options
        };

        if ( isValid( 'url', arguments.content ) ) {
            pdfRequest.append({
                'url' : arguments.content
            });
        }
        else {
            pdfRequest.append({
                'content' : arguments.content
            });
        }
        var requestArgs = {
            "output" : arguments.output,
            "requests" : [
              pdfRequest
            ]
        };

         return sendToPDFService(
            endpoint = this.getPDFURL(),
            body = local.requestArgs,
            retries = arguments.retries,
            timeout = arguments.timeout
        );
      
      /**
       * the non-hyper, cfhttp way; left here in case anybody wants to build in the option and have the handle* functions deal with it
        
        var method = ( pdfSettings.pdfSecure ? 'https' : 'http' );
        cfhttp(
            url = method & '://' & pdfsettings.pdfhost,
            port = pdfSettings.pdfPort,
            method = 'POST',
            getAsBinary = 'yes',
            result = 'pdfResponse'
        ) {
            cfhttpparam( type = 'body', value = serializeJson( requestArgs) );
        }
        */

    }

    public function toPDFMultiple( required array requests, string output = 'pdf',  retries = 0, timeout = 10  ) {
        
        var requestArray = requests.map( function( r ) {
            return r.toWkhtmltopdfRequest();
        } );

        var requestArgs = {
            "output" : arguments.output,
            "requests" : local.requestArray
        };

          return sendToPDFService(
            endpoint = this.getPDFURL(),
            body = local.requestArgs,
            retries = arguments.retries,
            timeout = arguments.timeout
        );
    }

    /**
     * handleResponseObject
     * @hint Takes the HyperResponse object from an wkhtmltopdf request, throws an error if it didn't get a 200 OK, or else returns the binary object
    */

     private function handleResponseObject( required hyper.models.HyperResponse response ) {
        if ( arguments.response.isError() ) {
            var errorMsg = 'wkhtmltopdf service reported status code ' & arguments.response.getStatusCode();
            if ( isSimpleValue ( arguments.response.getData() ) ) {
                local.errorMsg &= ': ' & arguments.response.getData();
            }
            
            throw(
                message = local.errorMsg,
                errorcode = arguments.response.getStatusCode(),
                detail = 'Attempted wkhtmltopdf connection to ' & getPDFURL()
            )                    
        }
        else if ( !isLucee() ) { // ACF needs us to run toByteArray() on the response
            return arguments.response.getData().toByteArray();
        }
        
        return arguments.response.getData();

    }

    public wkhtmltopdf.models.PDFRequest function toPDFRequest( 
        required string content,
        boolean isURL,
        struct options,
        struct cookies
    ) {
        return wirebox.getInstance( name = "PDFRequest@wkhtmltopdf", initArguments = arguments );
    }
    
}