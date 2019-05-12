if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/service-worker-handler.js', {
        scope: '/'
    }).then(function() {
        return navigator.serviceWorker.ready;
    }).then(function(registration) {
        registration.pushManager.subscribe({
            userVisibleOnly: true
        }).then(function(sub) {
            var endpointSections = sub.endpoint.split('/');
            var subscriptionId = endpointSections[endpointSections.length - 1];
            console.log(sub);
            db.collection("luanvv-user").doc(subscriptionId)
                .set({
                    subscriptionId: subscriptionId,
                    endpoint: sub.endpoint
                })
                .then(function(docRef) {
                    
                })
                .catch(function(error) {
                    console.error("Error adding document: ", error);
                });
        }).catch(function(error) {
            console.error('Service Worker Error', error);
        });;
    }).catch(function(error) {
        console.error('Service Worker Error', error);
    });
    navigator.serviceWorker.ready.then(function(registration) {
        // console.log('Service Worker Ready');
    });
}