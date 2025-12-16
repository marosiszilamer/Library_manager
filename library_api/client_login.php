<?php 

/*
*Establishing connection

*/
try
{
  include "db_con.php";
}catch(Exception $e)
{
    die(json_encode(["error" => "Connection failed: " . $e->getMessage()]));
}


	$conn = mysqli_connect($servername, $username, $password, $dbname);
	
	// Check connection
	if (!$conn) {
		echo json_encode(mysqli_connect_error());
	  die("Connection failed: " . mysqli_connect_error());
	}
	

	
	/*
*Feching data

*/

	$username = $_POST['username'];
	$password = $_POST['password'];
	
	//$username = "balazs01";
	//$password = "hash123";
	
	$password = hash("sha256",$password);


	


	$sql = "SELECT user_id,username,password_hash FROM users 
			WHERE username = '$username' AND password_hash = '$password';
			";

	$result = mysqli_query($conn,$sql);
	
	if (mysqli_connect_errno()) {
		echo "Failed to connect to MySQL: " . mysqli_connect_error();
		exit();
	}


	$count = mysqli_num_rows($result);
	/*$row = mysqli_fetch_assoc($result);
	$dt= date("Y-m-d h:i:s") ;
	echo var_dump($dt);
	$sql = "UPDATE users SET last_login='.$dt.' WHERE user_id='". $row["user_id"]."';";

	

	if (!mysqli_query($conn, $sql)) {
	
	  echo "Error updating record: " . mysqli_error($conn);
	}
	*/
	
	/*
*Giving a response to the dart code

*/
	if ($count == 1) {
		echo json_encode("Success");
	}else{
		echo json_encode("Error");
	}
	$conn=null;
	?>