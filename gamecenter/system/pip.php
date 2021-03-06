<?php

function pip()
{
	global $config;
    
    // Set our defaults
    $controller = $config['default_controller'];
    $action = 'index';
    $url = '';
	
	// Get request url and script url
	$request_url = (isset($_SERVER['REQUEST_URI'])) ? $_SERVER['REQUEST_URI'] : '';
	$request_info = parse_url($request_url);
	$request_url = $request_info['path'];
	$script_url  = (isset($_SERVER['PHP_SELF'])) ? $_SERVER['PHP_SELF'] : '';

	//var_dump($_SERVER, $request_url, $script_url, $_REQUEST);
	// Get our url path and trim the / of the left and the right
	if($request_url != $script_url) $url = trim(preg_replace('/'. str_replace('/', '\/', str_replace('index.php', '', $script_url)) .'/', '', $request_url, 1), '/');
    
	// Split the url into segments
	//var_dump($url);
	$segments = explode('/', $url);
	// Do our default checks
	if(isset($segments[0]) && $segments[0] != '') $controller = $segments[0];
	if(isset($segments[1]) && $segments[1] != '') $action = $segments[1];

	$segments = array_slice($segments, 2);
	if (PARA_ARRAY)
	{
		$result = array();
		for ($i = 0; $i < count($segments); $i += 2)
		{
			if (isset($segments[$i + 1]))
				$result[$segments[$i]] = $segments[$i + 1];
		}	
		$segments = array($result);
	}

	if (util::prehook($controller, $action, $segments))
	{
		return;
	}
	// Get our controller file
    $path = APP_DIR . 'controllers/' . $controller . '.php';
	if(file_exists($path)){
        require_once($path);
	} else {
        $controller = $config['error_controller'];
        require_once(APP_DIR . 'controllers/' . $controller . '.php');
	}
    
    // Check the action exists
    if(!method_exists($controller, $action)){
        $controller = $config['error_controller'];
        require_once(APP_DIR . 'controllers/' . $controller . '.php');
        $action = 'index';
    }
	
	// Create object and call method
	$obj = new $controller;
    die(call_user_func_array(array($obj, $action), $segments));
	util::afterhook($controller, $action, $segments);
}

?>
