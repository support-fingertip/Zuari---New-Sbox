({
	toastMsg : function (type, title, msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "type": type,
            "message": msg
        });
        toastEvent.fire();
    },
    // Strip non-digits and cap at 10 digits, writing the cleaned value back to the
    // field so it self-corrects in real time. Returns the cleaned value.
    sanitizePhone : function (fieldCmp) {
        var val = fieldCmp.get("v.value");
        if (val == null || val === '') {
            return val;
        }
        var clean = ('' + val).replace(/[^0-9]/g, '').slice(0, 10);
        if (clean !== val) {
            fieldCmp.set("v.value", clean);
        }
        return clean;
    }
})