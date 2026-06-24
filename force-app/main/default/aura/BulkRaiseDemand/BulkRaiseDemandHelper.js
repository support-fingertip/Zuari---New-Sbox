({
	showToast: function(component, title, message, type) {
        var notifLib = component.find("notifLib");
        notifLib.showToast({
            "variant": type,
            "title": title,
            "message": message
        });
    }
})