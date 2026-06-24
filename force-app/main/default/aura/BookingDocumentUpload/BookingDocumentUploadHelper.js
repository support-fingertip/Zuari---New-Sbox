({
    setupDocTypes : function(component) {
        component.set("v.docTypes", [
            'Applicant Aadhar Card Back',
            'Applicant Passport',
            'Co Applicant Passport Size Photo',
            'Sale Agreement',
            'Cheque Date',
            'DD',
            'Sale Deed',
            'Possession Letter',
            'Cancellation Agreement'
        ]);
    },

    setupColumns : function(component) {
        component.set("v.columns", [
            {
                label: "Preview",
                fieldName: "previewUrl",
                type: "image",
                fixedWidth: 120
            },
            {
                label: "File Name",
                fieldName: "fileName",
                type: "text"
            },
            {
                label: "Download",
                fieldName: "downloadUrl",
                type: "url",
                typeAttributes: { label: "Download", target: "_blank" }
            }
        ]);
    },

    fetchDocuments : function(component) {

        let action = component.get("c.getDocuments");
        action.setParams({
            recordId: component.get("v.recordId"),
            docNames: component.get("v.docTypes")
        });

        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {

                let rows = [];
                let data = response.getReturnValue();

                data.forEach(function(d) {

                    if (d.uploaded) {

                        let docId = d.documentId;
                        let fileName = d.fileName.toLowerCase();

                        let isImage = (
                            fileName.endsWith('.jpg') ||
                            fileName.endsWith('.jpeg') ||
                            fileName.endsWith('.png') ||
                            fileName.endsWith('.gif')
                        );

                        rows.push({
                            id: docId,
                            fileName: d.fileName,
                            isImage: isImage,
                            previewUrl: '/sfc/servlet.shepherd/version/download/' + docId,
                            downloadUrl: '/sfc/servlet.shepherd/document/download/' + docId,
                            documentId: docId
                        });
                    }
                });

                component.set("v.uploadedDocs", rows);
            }
        });

        $A.enqueueAction(action);
    }
});