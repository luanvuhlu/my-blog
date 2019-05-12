'use strict';
self.addEventListener('push', function(event) {
  var body;
  console.log(JSON.stringify(event.notification));
  if (event.data) {
    body = event.data.text();
  } else {
    body = 'Có bài viết mới!';
  }

  var options = {
    body: body,
    icon: 'images/notification-flat.png',
    vibrate: [100, 50, 100],
    data: {
      dateOfArrival: Date.now(),
      primaryKey: 1
    },
    actions: [
      {action: 'explore', title: 'Xem ngay',
        icon: 'images/checkmark.png'}
    ]
  };
  event.waitUntil(
    self.registration.showNotification("LUAN's blog", options)
  );
});
self.addEventListener('notificationclick', function(event) {
  // console.log('[Service Worker] Notification click Received.');
console.log('Push message', event);
  console.log(JSON.stringify(event))
  event.notification.close();

  event.waitUntil(
    clients.openWindow('/blog')
  );
});

// self.addEventListener('fetch', function(event) {
//   console.log("Ahihi");
//   console.log(event.request.url);
// });