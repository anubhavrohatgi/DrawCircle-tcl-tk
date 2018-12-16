#=================================
#==Developed by Anubhav Rohatgi=== 
#==Date : 23/04/2018==============
#=================================

#import the packages
package require Tk


#global variables
set pixelSize 10	 ;# size of virtual pixel in the canvas
set imSize 305		 ;# size of image dimensions are square
set point [list]	 ;# list of logical pixels over the logical grid. This is list of lists


#circle parameters
set cent(0,0) -1 	 ;# centerX of circle
set cent(0,1) -1    	 ;# centerY of circle
set cent(1,0) -1 	 ;# RadiusX of circle
set cent(1,1) -1 	 ;# RadiusY of circle


#TCL plotter assigned to widget
set widget .plot
catch {destroy $widget}
#this is required to unmap the window from the window manager(wm)
wm withdraw .
toplevel       $widget
wm title       $widget "Drawing Circle"
set mycanvas   $widget.mycanvas


#Create buttons for the window
tk::button $widget.exit -command ::exit -text Close
tk::button $widget.clear -command clear  -text Clear


#Create and paint the canvas with white background
tk::canvas $mycanvas -background white -height $imSize -width $imSize

#set the layout of the canvas and buttons
grid rowconfigure    $widget 0 -weight 0
grid rowconfigure    $widget 1 -weight 1

grid columnconfigure $widget 0 -weight 0
grid columnconfigure $widget 1 -weight 1


#this will set the geometry of the components of the window 
#and adjust them to fit the window size in a stretched 
#fashion in all directions
#south, west, east, north (swen)
grid $mycanvas     	-row 1 -column 0 -columnspan 2 -sticky swen
grid $widget.exit  	-row 2 -column 0               -sticky swen
grid $widget.clear 	-row 2 -column 1               -sticky swen



# # ###################### SETUP CANVAS & Logical Space #####################


#procedure for calculating the padding and spacing between the virtual pixels
#for this we need to either fix the pixelSize and calculate the spacing or
#fix the spacing/padding size and calculate the pixel size
#here we calculate the padding size. 	
proc calcGridSpacing { mGridSize } {
	#need to calculate padding/spacing
	global pixelSize imSize
	set padding [expr { int(ceil( ($imSize - ($mGridSize*$pixelSize))/($mGridSize+1))) }]
	#set padding [expr {int(($imSize % $pixelSize)/2)}]
	puts "Calculated Split Size: $padding"
	return $padding
}


#calculates and returns the central value of our logical pixel
# input is top left corner of the rect
# output is x,y of the pixel
proc calcLogicalCenterPixel {row col} {
	global pixelSize
	set x [expr {$col + ($pixelSize/2) }]
	set y [expr {$row + ($pixelSize/2) }]
	#puts "logical Center ($x,$y)"
	return  [list $x $y]
}



#calulate the padding size and assign it to a variable for 20x20 grid
set splitSize [calcGridSpacing 20]


#create logical grid and tag item
#procedure to make grid on the canvas. This will create an virtual grid/desktop
#the are the grid points
proc createGrid {} {

	#access global variables
	global splitSize imSize pixelSize pixelList mycanvas point

	#run loops for producing the grids
	for {set row $splitSize} {$row< [expr {$imSize-$splitSize}]} {set row [expr {$row + ($pixelSize + $splitSize)}]} {
	    for {set col $splitSize} {$col<[expr {$imSize-$splitSize}]} {set col [expr {$col + ($pixelSize + $splitSize)}]} {		     	 	
			#draw virual pixel on canvas
			set item [$mycanvas create rectangle $col $row [expr min($col+$pixelSize,$imSize)] \
			[expr min($row+$pixelSize,$imSize)] -fill gray -tag PIXEL]
			
			#add point to the point list
		        lappend point [calcLogicalCenterPixel $row $col]
			#this is required to map the rect to the point				
			$mycanvas addtag point withtag $item
	    }    
	}
}



#run the grid creation fn -- setup procedure
createGrid


# # ######################### DRAW CIRCLE PROCEDURE #####################


#Draws the circle on canvas 
#Input is Center(x,y), radius and thickness of perimeter line of the circle
#Outputs the circle on the canvas with the tag CIRCLE
proc draw_circle {circleObj color} {
  	global mycanvas	
    	set rad [lindex $circleObj 2] ;#radius of circle
	set cx  [lindex $circleObj 0] ;#center x coord of circle
	set cy  [lindex $circleObj 1] ;#center y coord of circle
	
     	set x1  [expr { $cx - $rad}]
     	set y1  [expr { $cy - $rad}]
     	set x2  [expr { $cx + $rad}]
     	set y2  [expr { $cy + $rad}]	
	#puts "Passed Center @ ($cx,$cy) rad : $rad"
	#puts "EndCoords for Diagonal Passing through Center from ($x1,$y1) to ($x2,$y2)"	
	
     	$mycanvas create oval $x1 $y1 $x2 $y2 -outline $color  -width [lindex $circleObj 3] -tag CIRCLE     
}






# # ######################### Triggers & Event Callbacks #####################

#=============================== Window Events ===============================
#to bind the close X button to exit event
wm protocol $widget WM_DELETE_WINDOW {
    if {[tk_messageBox -message "Are you sure you want to exit?" -type yesno] eq "yes"} {
       exit
    }
}


#=============================== Mouse Events =================================

#mouse click event with left button
#selects the logical pixel
bind $mycanvas <ButtonPress-1> { onLPress %x %y }
bind $mycanvas <B1-Motion> { onDragUpdateCircle %x %y}
bind $mycanvas <ButtonRelease-1> { onLRelease %x %y}

#procedure for left click mouse event
proc onLPress {x y} {
	clear ;# reset canvas

	global mycanvas 
	set x1 [$mycanvas canvasx $x] 
	set y1 [$mycanvas canvasy $y]
	
	#reference the global variable, values will be updated
	upvar 1 cent a
	set a(0,0) $x1
	set a(0,1) $y1	
	puts "Start Point (Left Button Pressed) : ($a(0,0),$a(0,1))"        
}

#procedure for left click + drag mouse event
proc onDragUpdateCircle {x y} {
	global mycanvas
        set x2 [$mycanvas canvasx $x] 
	set y2 [$mycanvas canvasy $y]

	#reference the global variable, values will be updated
	upvar 1 cent a
	set a(1,0) $x2
	set a(1,1) $y2
	puts "Drag Event : From ($a(0,0),$a(0,1)) to ($a(1,0),$a(1,1))"

	$mycanvas delete CIRCLE ;#delete old circle and update with the new 

	#inputs are centerX, centerY and Radius
	#call draw_circle procedure
	draw_circle [list $a(0,0) $a(0,1) [expr {abs($a(0,0) - $a(1,0))}] 4] black 	
}

proc onLRelease {x y} {

	global cent point splitSize pixelSize mycanvas

	if { $cent(1,0) > -1 || $cent(1,1) > -1 } {
		# Sets the user defined circle to blue color
		$mycanvas itemconfigure [$mycanvas find withtag CIRCLE] -outline blue 


		#this is the diagonal size of the pixel window
		#set threshDist [expr {sqrt(2.0*($splitSize+$pixelSize)*($splitSize+$pixelSize))}]

		set rad [expr {abs($cent(0,0) - $cent(1,0))}] ;#radius of the circle
		
		#parameters of interior and exterior radii and ptcount
		set inRadiiAvg 0
		set outRadiiAvg 0
		set inPtsCount 0
		set outPtsCount 0

		for {set i 0} {$i < [llength $point]} {incr i} {

			#this is the index of the item in the canvas itemlist canvas index starts from 1
			set itemIndex [expr {$i+1}] ;#actual current index i.e. our 1 is logical 0 and 400 is logical 399
			
			#equation of circle 
			#d^2=(x1−x0)^2+(y1−y0)^2
			# if d == rad then point is on the circle
			# if d > rad then point is outside the circle
			# if d < rad then point is in the circle

			#get the point from the point list
			set x1 [lindex $point $i 0]
			set y1 [lindex $point $i 1]
		
			#distance of a point from center
			set d [expr {sqrt( (($x1 - $cent(0,0))*($x1 - $cent(0,0))) + (($y1 - $cent(0,1))*($y1 - $cent(0,1))))} ]

			
			#we should relise that this point is nothing but center of the pixel also
			if { ($d >= [expr {$rad - ($pixelSize+$splitSize)/2.0}]) && ($d <= [expr {$rad + ($pixelSize+$splitSize)/2.0}]) } {
				
				#these points lie on the circle
				$mycanvas itemconfigure $itemIndex -fill blue ;#points on that lie on the circle

			} elseif {($d > [expr {$rad + ($pixelSize+$splitSize)/2.0}]) && ($d <= [expr {$rad + ($pixelSize+$splitSize)}]) } {

				#these points lie on the outside of the circle but within a threshold of pixel window size
				$mycanvas itemconfigure $itemIndex -fill green
				set outRadiiAvg [expr {$outRadiiAvg + $d}]
				set outPtsCount [expr {$outPtsCount + 1 }]

			} elseif {($d >= [expr {$rad - ($pixelSize+$splitSize)}]) && ($d < [expr {$rad + ($pixelSize+$splitSize)/2.0}]) } {

						#these points lie on the inside of the circle but within a threshold of pixel window size
						$mycanvas itemconfigure $itemIndex -fill pink
						set inRadiiAvg [expr {$inRadiiAvg + $d}]
						set inPtsCount [expr {$inPtsCount + 1 }]

			} else {
				#do nothing
			}
		}

		set outRadiiAvg [expr {$outRadiiAvg/($outPtsCount+0.00001)} ] ;#added some delta to avoid divide by zero error
		set inRadiiAvg [expr {$inRadiiAvg/($inPtsCount+0.00001)} ] ;#added some delta to avoid divide by zero error
		draw_circle [list $cent(0,0) $cent(0,1) $outRadiiAvg 1] red 	
		draw_circle [list $cent(0,0) $cent(0,1) $inRadiiAvg 1] red 	

		#puts "DONEDONE------------ ($cent(1,0),$cent(1,1))"

	}	

}



#========================== RESET PROCEDURES ====================

#clear the canvas and reset PIXELS to gray
proc clear {} {
    global mycanvas    
     
    foreach i [$mycanvas find withtag PIXEL] { 
    	$mycanvas itemconfigure $i -fill gray 
    }

    foreach i [$mycanvas find withtag CIRCLE] { 
    	$mycanvas delete $i 
    }
}


# # ## ### ##### ######## ############# #####################
## Invoke event loop.

vwait __forever__
exit

