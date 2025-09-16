
component {

	// Module Properties
	this.title 				= "wkhtmltopdf";
	this.author 			= "Samuel Knowlton <sam@inleague.io>";
	this.webURL 			= "https://www.inleague.io";
	this.description 		= "A Coldbox wrapper for wkhtmltopdf, inspired by Ryan Guill and the wkhtmltopdf-as-a-service Docker container (https://github.com/MotorsportReg/docker-wkhtmltopdf-service) though Docker is not required ";
	this.version			= "1.2.0";
	// If true, looks for views in the parent first, if not found, then in the module. Else vice-versa
	this.viewParentLookup 	= false;
	// If true, looks for layouts in the parent first, if not found, then in module. Else vice-versa
	this.layoutParentLookup = false;
	// Module Entry Point
	this.entryPoint			= "wkhtmltopdf";
	// Inherit Entry Point
	this.inheritEntryPoint 	= false;
	// Model Namespace
	this.modelNamespace		= "wkhtmltopdf";
	// CF Mapping
	this.cfmapping			= "wkhtmltopdf";
	// Auto-map models
	this.autoMapModels		= true;
	// Module Dependencies
	this.dependencies 		= [ "hyper"  ];

	function configure(){

		// parent settings
		parentSettings = {

		};

		// module settings - stored in modules.name.settings
		settings = {
			pdfhost			=  'wkhtmltopdf',		// hostname for wkhtmltopdf container. Default assumes a internal network hostname lookup, but a FQDN is fine (e.g. wkhtmltopdf.mycompany.com). Do not include http/https
			pdfport			=	3000,				// http/s port for wkhtmltopdf service. default of 3000 is used by the wkhtmltopdf docker container
			pdfsecure		=	false				// false = http, true = https
		};

	}

	/**
	* Fired when the module is registered and activated.
	*/
	function onLoad(){

	}

	/**
	* Fired when the module is unregistered and unloaded
	*/
	function onUnload(){

	}

}