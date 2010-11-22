$.download = function(url, data, method, callback){
	var inputs = '';
	var iframeX;
	var downloadInterval;
	if(url && data){
		// remove old iframe if any
		if($("#iframeX")) $("#iframeX").remove();
		// create new iframe
		iframeX= $('<iframe src="javascript:false;" name="iframeX" id="iframeX"></iframe>').appendTo('body').hide();

		if(iframeX.attachEvent){
			iframeX.attachEvent("load", function(){
				callback();
			});
		} else {
			iframeX.load(function() {
				callback();
			});
		} 

		//split params into form inputs
		$.each(data, function(p, val){
			val = val.replace(/"/g,"'"); 
			inputs += '<input type="hidden" name="' + p + '" value="' + val + '" />';
		});

		//create form to send request
		$('<form action="' + url + '" method="' + (method||'post') + '" target="iframeX">' + inputs + '</form>').appendTo('body').submit().remove();
	};
};
