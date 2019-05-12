const DB_NAME = "luanvv-comment";
function addComment(data){
	db.collection(DB_NAME).add({
	    first: "Ada",
	    last: "Lovelace",
	    born: 1815
	})
	.then(function(docRef) {
	    console.log("Document written with ID: ", docRef.id);
	})
	.catch(function(error) {
	    console.error("Error adding document: ", error);
	});
}

function loadComment(){
	db.collection(DB_NAME).get().then((querySnapshot) => {
	    querySnapshot.forEach((doc) => {
	        console.log(`${doc.id} => ${doc.data()}`);
	    });
	});
}