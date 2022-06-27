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
     * toPDF
     * @hint A simple wrapper for a single input stream
     * @html String to convert to PDF
     * @options Struct for wkhtmltopdf options
     * @output desired output from wkhtmltopdf: pdf, png, or jpg
    */

    public function toPDF( required string content, struct options = {}, string output = 'pdf' ) {
        
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

        var pdfResponse = wirebox.getInstance( "HyperBuilder@hyper" )
            .setBaseURL( getPDFURL() )
            .setMethod( "POST" )
            .asJSON()
            .setBody( local.requestArgs )
            .send();
      
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

        return handleResponseObject( response = pdfResponse );
    }

    public function toPDFMultiple( required array requests, string output = 'pdf' ) {
        
        var requestArray = requests.map( function( r ) {
            return r.toWkhtmltopdfRequest();
        } );

        var requestArgs = {
            "output" : arguments.output,
            "requests" : local.requestArray
        };

        var pdfResponse = wirebox.getInstance( "HyperBuilder@hyper" )
            .setBaseURL( getPDFURL() )
            .setMethod( "POST" )
            .asJSON()
            .setBody( local.requestArgs )
            .send();
        
        return handleResponseObject( response = local.pdfResponse );
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