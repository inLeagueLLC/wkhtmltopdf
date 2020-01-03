# wkhtmltopdf (A Coldbox Wrapper)
After years of wrestling with cfdocument from Adobe and Lucee, we did the smart thing and centralized our "convert this to PDF" functions using a wkhtmltopdf Docker container based on this repository:

https://github.com/MotorsportReg/docker-wkhtmltopdf-service

All this module does is provide a friendly interface to the API for that service. **This module does not contain wkhtmltopdf or do any conversion by itself**. You must be running wkhtmltopdf as a service for this module to do any good.

It was inspired by a recommendation and some sample code form Ryan Guill on the CFML Slack. 

## Requirements:
* Supported Engines: Lucee 5+, Adobe Coldfusion 11+
* a wkhtmltopdf service accessible to your CF engine
* Coldbox

## Usage

Instantiate the PDF Service:

`property name="PDFService" inject="PDFService@wkhtmltopdf";`

or

`PDFService = wirebox.getInstance( "PDFService@wkhtmltopdf" );`

### Converting a single content string

For simple requests, use the `toPDF` function:

```
var myPDF = PDFService.toPDF(
  html = '<html><head><title>A Sample PDF</title></head><body><p>Some Sample Content</p></body></html>'
);
```

### Rendering the Result

PDFService returns a binary object. While Coldbox's **renderData()** convention makes it very easy to convert anything to PDF (or JSON, or HTML), you're at the mercy of the application engine's PDF library -- and you have to include the PDF extension in your deployment (for Lucee) or the Adobe PDF Service (for ACF). Since PDFService gives us a binary object, here's how we would display the **myPDF** object above:

```
     return event.renderData( 
       data = myPDF,
       isBinary = true,
       contentType = "application/pdf"
     );
```

### Error Handling

If PDFService gets anything other than a **200 OK** from wkhtmltopdf, either because it can't connect or the wkhtmltopdf service returns an error code, PDFService will throw an exception along with the HTTP Status code from the attempted connection to wkhtmltopdf. 

### But I don't have Coldbox!

This module uses Coldbox to simplify some of the more complex use cases (like asking for multiple source documents, or mixed URL and content requests). It's not at all necessary to use Coldbox to take advantage of wkhtmltopdf. You could start by using Ryan's sample code (converted to cfscript)
```
public binary function printPDF(
  required string html,
  struct options = {}
) {
  var args = {
    "output" : "pdf",
    "request" [
      {
        "content" : arguments.html,
        "options" : arguments.options
      }
    ]
  };
  
  cfhttp(
    url = "URLtoMywkhtmltopdfService",
    method = "POST",
    result = "local.httpResult",
    throwonerror = true
  ) {
    cfhttpparam( type="body" value = serializeJSON( args ) );
  }
  
  return httpResult.fileContent.toByteArray();
}
  ```
