MacroScript LoadSQBookmarks category:"Sequoia" buttontext:"SQBM"
(
	---------------------------------------------------------------------------------
	--SEQUOIA BOOKMARKS TO 3DS MAX CAMERAS SCRIPT
	--by Borislav 'Bobo' Petrov
	--Thinkbox Software, Inc.
	--March 29, 2016
	---------------------------------------------------------------------------------
	
	global LoadSQBookmarks_Rollout
	try(destroyDialog LoadSQBookmarks_Rollout)catch()
	
	rollout LoadSQBookmarks_Rollout "Load Sequoia Bookmarks"
	(
		button btn_pickFile "..." across:2 width:30 height:18 align:#left offset:[-7,0] tooltip:"Select a Hacksaw Sequence file..."
		edittext edt_file "" fieldwidth:350 align:#right
		
		group "Options"
		(
			checkbox chk_deletePrevious "DELETE Existing 'SQBookmark_' Objects Before Creating New Ones" checked:true
			checkbox chk_createAnimation "ANIMATE A Camera Through Bookmarks" checked:true across:2 align:#left
			spinner spn_cameraSpeed "FRAMES / Bookmark:" range:[1,100000,30] type:#integer fieldwidth:30 align:#right offset:[0,1]
		)
		button btn_load "CREATE CAMERAS FROM BOOKMARKS" width:390 height:30 align:#center enabled:false
		
		dropdownlist ddl_cameras "Set Viewport To Camera:"

		fn loadCameras =
		(
			theCameras = for i in Cameras where classof i != TargetObject collect i
			ddl_cameras.items = for c in theCameras collect c.name
		)		
		
		fn animateCameras theCameras =
		(
			local newCamera = freeCamera name:(uniquename "SQBookmark_Animation_")
			local theTime = 100
			for c = 1 to theCameras.count do
			(
				with animate on
				(
					theTime = ((c-1)*spn_cameraSpeed.value)
					at time theTime 
						newCamera.transform = theCameras[c].transform
				)
			)
			animationRange = interval 0 theTime
		)
		
		fn updateUI =
		(
			btn_load.enabled = doesFileExist edt_file.text
		)
		
		fn readJSONValue theFile =
		(
			(filterString (readLine theFile) ":,")[2]
		)
		
		fn readSequoiaBookmarks thePath =
		(
			local allCameras = #()
			local theFile = openFile thePath
			local theCamera
			local systemScale = case units.SystemType of
			(
				defaullt: 1.0
				#centimeters: 100.0
				#millimeters: 1000.0
				#kilometers: 0.001
				#inches: 39.3701
				#feet: 3.28084
				#miles: 0.000621371
			)

			if theFile != undefined do
			(
				local theLine = readLine theFile
				if not matchPattern theLine pattern:"*[*" do 
				(
					close theFile
					return false
				)
				bracesCounter = 0
				createCamera = false
				camerasArray = #()
				while not eof theFile do
				(
					theLine = readLine theFile
					if matchPattern theLine pattern:"*{*" do bracesCounter +=1
					if bracesCounter == 1 and not createCamera do 
					(
						createCamera = true
						append camerasArray #()
						theCamera = FreeCamera name:(uniquename "SQBookmark_")
						append allCameras theCamera
					)
					if bracesCounter > 1 do 
					(	
						if matchPattern theLine pattern:"*direction*" then
						(
							theW = readJSONValue theFile 
							theX = readJSONValue theFile 
							theY = readJSONValue theFile 
							theZ = readJSONValue theFile 
							theCamera.rotation = execute ("quat "+theX +" "+theY+" " +theZ +" "+theW)
						)
						else if matchPattern theLine pattern:"*position*" then
						(
							theX = readJSONValue theFile 
							theY = readJSONValue theFile 
							theZ = readJSONValue theFile 
							theCamera.position = (execute ("(point3 "+theX +" "+ theY +" "+ theZ+")"))*systemScale
						)		
					)
					if bracesCounter == 1 do 
					(
						if matchPattern theLine pattern:"*isortho*" do 
						(
							theVal = (filterString theLine ":,")[2]
							theCamera.orthoProjection = matchPattern theVal pattern:"*true*"
						)					
						if matchPattern theLine pattern:"*near*" do 
						(
							theVal = execute (filterString theLine ":,")[2]
							theCamera.nearclip = theVal * systemScale
						)		
						if matchPattern theLine pattern:"*far*" do 
						(
							theVal = execute (filterString theLine ":,")[2]
							theCamera.farclip =  theVal * systemScale
						)		
						if matchPattern theLine pattern:"*focusdistance*" do 
						(
							theVal = execute (filterString theLine ":,")[2]
							theCamera.baseobject.targetDistance =  theVal * systemScale
						)						
					)
					if matchPattern theLine pattern:"*}*" do bracesCounter -=1
					if bracesCounter == 0 and createCamera do createCamera = false
				)--end while loop
				close theFile
			)--end if
			if chk_createAnimation.checked do animateCameras allCameras
			loadCameras()
			ddl_cameras.selection = ddl_cameras.items.count	
			theCamera = getNodeByName ddl_cameras.selected
			if isValidNode theCamera do viewport.setCamera theCamera
			true
		)--end fn
		
		on btn_pickFile pressed do
		(
			local theFile = getOpenFilename title:"Select A Sequoia Bookmarks File..." types:"Sequoia Bookmarks (*.sqbm)|*.sqbm"
			if theFile != undefined do
			(
				edt_file.text = theFile
				updateUI()
			)
		)
		
		on edt_file changed txt do
		(
			updateUI()
		)		

		on btn_load pressed do
		(
			if chk_deletePrevious.checked do delete $SQBookmark_*
			readSequoiaBookmarks edt_file.text
		)
		
		on ddl_cameras selected itm do
		(
			theCamera = getNodeByName ddl_cameras.selected
			if isValidNode theCamera do 
			(
				viewport.setCamera theCamera
				select theCamera
			)
		)
		
		on LoadSQBookmarks_Rollout open do
		(
			loadCameras()
			theCamera = viewport.getCamera()
			if isValidNode theCamera do
			(
				theIndex = findItem ddl_cameras.items theCamera.name
				if theIndex > 0 do ddl_cameras.selection = theIndex
			)
		)
	)
	
	createDialog LoadSQBookmarks_Rollout 400 180
)