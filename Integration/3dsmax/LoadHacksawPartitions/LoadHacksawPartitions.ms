macroScript LoadSQHacksaw category:"Sequoia" buttontext:"SQHS"
(
	global LoadHacksawPartitions_Rollout
	try(destroyDialog LoadHacksawPartitions_Rollout)catch()
	
	rollout LoadHacksawPartitions_Rollout "Load Sequoia Hacksaw Partitions"
	(
		button btn_pickFile "..." across:3 width:22 height:18 align:#left offset:[-10,0] tooltip:"Select a Hacksaw Sequence file..."
		edittext edt_file "" fieldwidth:348 align:#center
		button btn_fromScene "<S" align:#right width:22 height:18 offset:[12,0] tooltip:"Get file from a selected XMesh Loader..."
		
		group "Partition Options"
		(
			checkbox chk_loadSubset "Load Subset" enabled:false checked:true across:3
			spinner spn_start "From:" fieldwidth:40 type:#integer enabled:false 
			spinner spn_end "To:" fieldwidth:40 type:#integer enabled:false 
			button btn_selectSubset ">S" pos:[100,45] width:25 height:18 tooltip:"If XMeshes already exist in the scene, select the ones in the specified subset."
		)
		
		group "Material Options"
		(
			checkbox chk_assignMaterials "Assign Materials" enabled:false checked:true across:2 
			checkbox chk_selfIlluminated "Self-Illuminated Textures" enabled:false checked:true 
			checkbox chk_showTextures "Show Textures In Viewport" enabled:false checked:true across:2
			dropdownlist ddl_textureLimit items:#("512","1024","2048","4096","8192") selection:2 align:#right width:55 offset:[0,-2]
			label lbl_1 "Set Nitrous Texture Limit:" offset:[-65,-25] align:#right tooltip:"You can set this value after the XMesh Loaders have been created!"
			label lbl_2 "" offset:[0,-12]
		)
		
		progressbar prg_progress width:390 height:8 color:blue value:0 align:#center
		button btn_loadPartitions "CREATE XMESH LOADERS..." enabled:false width:390 height:30 align:#center
		
		group "Post-Creation Management Tools"
		(
			button btn_selectAllXMeshes "SELECT All XMeshes" width:185 across:2 align:#left
			button btn_invertSelection "INVERT XMesh Selection" width:185 align:#right

			button btn_enableVC "SHOW Selected Vertex COLORS" width:185 across:2 align:#left
			button btn_disableVC "HIDE Selected Vertex COLORS" width:185 align:#right
			
			button btn_enableAllTextures "SHOW Selected TEXTURES" width:185 across:2 align:#left
			button btn_disableAllTextures "HIDE Selected TEXTURES" width:185 align:#right
			button btn_enableSelfIllum "SHOW Selected Sefl-ILLUMINATION" width:185 across:2 align:#left
			button btn_disableSelfIllum "HIDE Selected Sefl-ILLUMINATION" width:185 align:#right
			
		)
		

		fn getPossibleTextures theFile=
		(
			for i in (getFiles (getFileNamePath theFile + getFileNameFile theFile + ".*")) where findItem #(".jpg",".png",".tga",".exr") (tolower (getFileNameType i)) > 0 collect i
		)
		
		fn getZeros theNumber count:4=
		(
			local theStr = theNumber as string
			local theCount = count-(theStr.count)
			if theCount < 1 then "" else substring "00000000000" 1 theCount					
		)
		
		fn getAllPartitions theFile =
		(
			if doesFileExist theFile then
			(
				local theBaseName = getFileNameFile theFile
				local lastDigit = theBaseName.count
				for i = theBaseName.count to 1 by -1 do
				(
					if findItem #("0","1","2","3","4","5","6","7","8","9") theBaseName[i] > 0 then
						lastDigit = i
					else
						exit
				)
				local thePartCount = substring theBaseName lastDigit -1
				if matchPattern theBaseName pattern:("*of"+thePartCount) then
				(
					local theSubBaseName = substring theBaseName 1 (theBaseName.count - (thePartCount.count*2)  - 2)
					local theDigitsCount = thePartCount.count
					local theCountAsInteger = execute thePartCount
					allFiles = for i = 1 to theCountAsInteger collect
					(
						local theFileToGet = getFileNamePath theFile + theSubBaseName + (getZeros i count:theDigitsCount) + i as string + "of" + thePartCount + (getFileNameType theFile)
						local isExistingNode = isValidNode (getNodeByName ("XMesh_"+ getfilenamefile theFileToGet))
						#(theFileToGet, doesFileExist theFileToGet, isExistingNode)
					)
					--allFiles = getFiles (getFileNamePath theFile + theSubBaseName + "*" + "of" + thePartCount + getFileNameType theFile)
					--sort allFiles
				)
				else
				(
					local isExistingNode = isValidNode (getNodeByName ("XMesh_"+ getfilenamefile theFile))
					#(#(theFile, true, isExistingNode))
				)
			)
			else
				#()
		)
		
		fn updateButton =
		(
			local allFiles = getAllPartitions edt_file.text
			local existingParts = (for i in allFiles where i[2] collect i).count
			local countToCreate = existingParts
			if chk_loadSubset.checked then 
				countToCreate = (for i = spn_start.value to spn_end.value where allFiles[i][2] and not allFiles[i][3] collect i).count
			else
				countToCreate = (for i = 1 to allFiles.count where allFiles[i][2] and not allFiles[i][3] collect i).count
			local existingLoaders = (for i = 1 to allFiles.count where allFiles[i][2] and allFiles[i][3] collect i).count
			local txt = "CREATE "+ countToCreate as string + " XMESH LOADER"+ (if countToCreate == 1 then "" else "S")+ " OUT OF "+ allFiles.count as string 
			if existingLoaders > 0 do txt+= " - " +existingLoaders as string + " ALREADY CREATED"
			btn_loadPartitions.text = txt
		)
		
		fn updateUI =
		(
			local allParts = (getAllPartitions edt_file.text).count
			btn_loadPartitions.enabled = doesFileExist edt_file.text
			spn_start.enabled = spn_end.enabled = chk_loadSubset.enabled = allParts > 1
			spn_start.range = [1,allParts,1]
			spn_end.range = [1,allParts,allParts]
			chk_selfIlluminated.enabled = chk_showTextures.enabled = chk_assignMaterials.enabled = (getPossibleTextures edt_file.text).count > 0 
			updateButton()
		)
		
		on chk_loadSubset changed state do updateButton()	
		
		on spn_start changed val do
		(
			if val > spn_end.value do spn_end.value  = val
			updateButton()	
		)
		on spn_end changed val do
		(
			if val < spn_start.value do spn_start.value  = val
			updateButton()
		)
		
		on btn_pickFile pressed do
		(
			local theFile = getOpenFilename title:"Select One Hacksaw Partition File..." types:"Thinkbox XMesh (*.xmesh)|*.xmesh|Wavefront OBJ (*.obj)|*.obj"
			if theFile != undefined do
			(
				edt_file.text = theFile
			)
			updateUI()
		)
		on edt_file changed txt do
		(
			updateUI()
		)
		
		on ddl_textureLimit selected itm do
		(
			NitrousGraphicsManager.SetTextureSizeLimit (ddl_textureLimit.selected as integer) true
		)
		
		on btn_fromScene pressed do
		(
			theXMeshes = for o in selection where classof o.baseobject == XMeshLoader collect o
			if theXmeshes.count > 0 do 
			(
				edt_file.text = theXmeshes[1].renderSequence
				updateUI()
			)
		)
		on btn_selectAllXMeshes pressed do
		(
			select (for o in geometry where classof o.baseobject == XMeshLoader collect o)
		)
		on btn_invertSelection pressed do
		(
			local deselectedXMeshes = for o in geometry where classof o.baseobject == XMeshLoader and not o.isSelected collect o
			max select none
			select deselectedXMeshes
		)		
		on btn_enableAllTextures pressed do
		(
			for o in selection where classof o.baseobject == XMeshLoader and o.material != undefined do
			(
				showTextureMap o.material true
				o.showVertexColors  = false
			)
		)
		on btn_disableAllTextures pressed do
		(
			for o in selection where classof o.baseobject == XMeshLoader and o.material != undefined do
			(
				showTextureMap o.material false
			)
		)	
		on btn_enableVC pressed do
		(
			for o in selection where classof o.baseobject == XMeshLoader do
			(
				if o.material != undefined do showTextureMap o.material false
				o.showVertexColors  = true
				o.vertexColorType = #color
			)
		)	
		on btn_disableVC pressed do
		(
			for o in selection where classof o.baseobject == XMeshLoader do
			(
				o.showVertexColors  = false
				o.vertexColorType = #color
			)
		)	
		on btn_enableSelfIllum pressed do
		(
			for o in selection where classof o.baseobject == XMeshLoader and o.material != undefined do
			(
				o.material.selfIllumAmount = 100.0
			)			
		)
		on btn_disableSelfIllum pressed do
		(
			for o in selection where classof o.baseobject == XMeshLoader and o.material != undefined do
			(
				o.material.selfIllumAmount = 0.0
			)			
		)				
		on btn_selectSubset pressed do
		(
			if doesFileExist edt_file.text do
			(
				local allFiles = getAllPartitions edt_file.text
				local toSelect = for i = spn_start.value to spn_end.value where allFiles[i][2] collect
				(
					theNode = (getNodeByName ("XMesh_"+getFileNameFile allFiles[i][1])) 
					if isValidNode theNode then theNode else dontcollect
				)
				select toSelect 
			)
		)
		
		on btn_loadPartitions pressed do
		(
			local newObjects = #()
			with undo "LoadSQHacksaw" on
			(
				local theFiles = getAllPartitions edt_file.text 
				local startFrame = 1
				local endFrame = theFiles.count
				if chk_loadSubset.checked do
				(
					startFrame = spn_start.value
					endFrame = spn_end.value
				)
				local cnt = 0
				for f = startFrame to endFrame do
				(
					windows.processPostedMessages()
					cnt += 1
					prg_progress.value = 100.0*cnt/(endFrame-startFrame+1)
					if theFiles[f][2] do
					(
						local theCurrentFile = theFiles[f][1]
						local isExistingNode = getNodeByName ("XMesh_"+ getfilenamefile theCurrentFile)
						if not isValidNode isExistingNode do
						(
							local theLoader = XMeshLoader()
							theLoader.renderSequence = theCurrentFile
							theLoader.name = "XMesh_"+getfilenamefile theCurrentFile
							theLoader.loadSingleFrame = true
							theLoader.useFileLengthUnit = true
							theLoader.viewportSequenceID = 0
							theLoader.showIcon = false
							append newObjects theLoader
							if chk_assignMaterials.checked do
							(
								local theTextures = getPossibleTextures theCurrentFile
								if theTextures.count > 0 do
								(
									local theMat = StandardMaterial name:("MAT_"+getFileNameFile theCurrentFile)
									theMat.diffusemap = bitmapTexture name:("MAP_"+getFileNameFile theCurrentFile) filename:theTextures[1]
									if chk_selfIlluminated.checked do theMat.selfIllumAmount = 100.0
									theLoader.material = theMat
									showTextureMap theMat chk_showTextures.checked
								)
							)
							--max views redraw
							max zoomext sel all
						)--end if node does not exist
					)--end if exists
				)
				if chk_assignMaterials.checked  do	NitrousGraphicsManager.SetTextureSizeLimit (ddl_textureLimit.selected as integer) true
				select newObjects
				max zoomext sel all
				prg_progress.value = 0
				updateUI()
			)--end undo
		)
		on LoadHacksawPartitions_Rollout moved pos do
		(
			setIniSetting (getDir #plugcfg+"//SQ_LoadHacksawPartitions.ini") "Dialog" "Position" (pos as string)
		)
	)
	val = execute (getIniSetting (getDir #plugcfg+"//SQ_LoadHacksawPartitions.ini") "Dialog" "Position" )
	if val != OK then
		createDialog LoadHacksawPartitions_Rollout 400 320 val.x val.y
	else
		createDialog LoadHacksawPartitions_Rollout 400 320
)