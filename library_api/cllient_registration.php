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
	$password = $_POST['email'];
	$password = $_POST['first_name'];
	$password = $_POST['last_name'];
	$password = $_POST['phone'];
	$password = $_POST['address'];
	$password = $_POST['city'];
	$password = $_POST['postal_code'];
	
	$dt= date("Y-m-d h:i:s") ;
	//echo $dt;
	//echo var_dump($dt);
	$sql = "UPDATE users SET last_login='.$dt.' WHERE user_id='". $row["user_id"]."';";

	
	$password = hash("sha256",$password);


	


	$sql = "INSERT INTO all users ( );
			";

	$result = mysqli_query($conn,$sql);
	
	if (mysqli_connect_errno()) {
		echo "Failed to connect to MySQL: " . mysqli_connect_error();
		exit();
	}


	$count = mysqli_num_rows($result);

	
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