#=================================
#==Developed by Anubhav Rohatgi=== 
#==Date : 18/04/2018==============
#=================================

#import the packages
package require Tk

#global variables
set pixelSize 10	;# size of virtual pixel in the canvas
set imSize 305		;# size of image dimensions are square
set point [list]	;# list of logical pixels over the logical grid. This is list of lists
set selectedItems [list] ;# list of selected items indices



#TCL plotter assigned to widget
set widget .plot
catch {destroy $widget}
#this is required to unmap the window from the window manager(wm)
wm withdraw .
toplevel       $widget
wm title       $widget "Digitizing Circle"
set mycanvas   $widget.mycanvas


#Create buttons for the window
button $widget.exit -command ::exit -text Close
button $widget.clear -command clear  -text Clear
button $widget.generate -command generate  -text Generate ;#when clicked generates best fir circle


#Create and paint the canvas with white background
canvas $mycanvas -background white -height $imSize -width $imSize

#set the layout of the canvas and buttons
grid rowconfigure    $widget 0 -weight 0
grid rowconfigure    $widget 1 -weight 1

grid columnconfigure $widget 0 -weight 0
grid columnconfigure $widget 1 -weight 1
grid columnconfigure $widget 2 -weight 0


#this will set the geometry of the components of the window 
#and adjust them to fit the window size in a stretched 
#fashion in all directions
#south, west, east, north (swen)
grid $mycanvas     	-row 1 -column 0 -columnspan 3 -sticky swen
grid $widget.exit  	-row 2 -column 0               -sticky swen
grid $widget.generate  	-row 2 -column 1               -sticky swen
grid $widget.clear 	-row 2 -column 2               -sticky swen


#Triggers and events
#currently disabled highlihgting as it is not allowing to set the color
#keeps on updating the color to blue
#canvas::highlight on $mycanvas POINT  _COLOR

#mouse click event with left button
#selects the logical pixel
bind $mycanvas <Button-1> { onClick %x %y }
proc onClick {x y} {
	global mycanvas selectedItems point
        set x [$mycanvas canvasx $x] 
	set y [$mycanvas canvasy $y]
        set i [$mycanvas find closest $x $y]
        set t [$mycanvas gettags $i]
	$mycanvas itemconfigure $i -fill blue
	set lastVal [lindex $selectedItems end]

	#to avoid duplicate points
	if { $lastVal != $i} { 
		lappend selectedItems $i	
	}
	#Display n-1th element as we are starting the index from 1 and not 0        
        puts "The Selected item : [expr {$i-1}] @ ([lindex $point [expr {$i-1}] 0],[lindex $point [expr {$i-1}] 1])"
}



#Callbacks for setting  highlighting points
namespace eval _COLOR {
    namespace export on off
    namespace ensemble create
}

proc _COLOR::on {mycanvas item} {
    set old [lindex [$mycanvas itemconfigure $item -fill] end]
    $mycanvas itemconfigure $item -fill blue
    return [list $item $old]
}

proc _COLOR::off {mycanvas cd} {
    lassign $cd item oldfill
    $mycanvas itemconfigure $item -fill $oldfill
    return 1
}



#procedure for calculating the padding and spacing between the virtual pixels
#for this we need to either fix the pixelSize and calculate the spacing or
#fix the spacing/padding size and calculate the pixel size
#here we calculate the padding size. 	
proc calcGridSpacing {mGridSize } {
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


#calulate the padding size and assign it to a variable
set splitSize [calcGridSpacing 20]


#set the logicalSpace dimensions/rect for the grid boundary info
set logicalSpace [list $splitSize $splitSize [expr {$imSize-$splitSize}] [expr {$imSize-$splitSize}] ]


#Just for checking/debugging
#puts [llength $point]
#for {set i 0} {$i < [llength $point]} {incr i} {
#	puts "[lindex $point $i 0],[lindex $point $i 1]"
#}



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
			[expr min($row+$pixelSize,$imSize)] -fill gray -tag POINT]
			
			#add point to the point list
		        lappend point [calcLogicalCenterPixel $row $col]
			#this is required to map the rect to the point				
			$mycanvas addtag point withtag $item
	    }    
	}
}

#Draws the circle on canvas 
#Input is Center(x,y) and radius of the circle
#Outputs the circle on the canvas with the tag CIRCLE
proc draw_circle {circleObj} {
  	global mycanvas	
    	set rad [lindex $circleObj 2] ;#radius of circle
	set cx  [lindex $circleObj 0] ;#center x coord of circle
	set cy  [lindex $circleObj 1] ;#center y coord of circle
	
     	set x1  [expr { $cx - $rad}]
     	set y1  [expr { $cy - $rad}]
     	set x2  [expr { $cx + $rad}]
     	set y2  [expr { $cy + $rad}]	
	#puts "Passed Center @ ($cx,$cy) rad : $rad"
	puts "EndCoords for Diagonal Passing through Center from ($x1,$y1) to ($x2,$y2)"	
	
     	$mycanvas create oval $x1 $y1 $x2 $y2 -outline black  -width 3 -tag CIRCLE     
}


#calculate the best fit circle using least squares fitting technique
#ref: http://jsxgraph.uni-bayreuth.de/wiki/index.php/Least-squares_circle_fitting
#ref: https://www.codeproject.com/Questions/228108/Linear-least-squares-circle-fit-in-C-or-Cplusplus
#ref: https://stackoverflow.com/questions/44647239/how-to-fit-a-circle-to-a-set-of-points-with-a-constrained-radius

#                   A        B         C      R        R
#         G1:  +2*a*x^2 +2*b*x*y  +2*c*x +2*x^3    +2*x*y^2  = 0
#         G2:  +2*a*x*y +2*b*y^2  +2*c*y +2*y^3    +2*x^2*y  = 0
#         G3:  +2*a*x   +2*b*y    +2*c   +2*y^2    +2*x^2    = 0

proc calc_circle {indxs pts} {
	set n [llength $indxs]
	catch {unset A; unset B}
	
	#LHS	
	set A(0,0) 0; set A(0,1) 0; set A(0,2) 0
	set A(1,0) 0; set A(1,1) 0; set A(1,2) 0
	set A(2,0) 0; set A(2,1) 0; set A(2,2) 0
	#RHS
	set B(0) 1; set B(1) 0; set B(2) 0
	
	#iterate over the data
	for {set i 0} {$i < $n} {incr i} {
		puts "Calc : [lindex $indxs $i]"
		set curInd [expr {[lindex $indxs $i]-1}] ;#actual current index i.e. our 1 is logical 0 and 400 is logical 399
		set X [lindex $pts $curInd 0]
		set Y [lindex $pts $curInd 1]			
		puts "CalcCircle : X,Y ([lindex $pts $curInd 0],[lindex $pts $curInd 1]) @ Indx $curInd"
		
		#col 0 = A / col 1 = B / col 2 = C
		set X2 [expr {$X * $X }]
		set X3 [expr {$X * $X * $X }]
		set Y2 [expr {$Y * $Y }]
		set Y3 [expr {$Y * $Y * $Y }]

		#Row 0 = G1
		set A(0,0) [expr {$A(0,0) + (2 * $X2)}]
		set A(0,1) [expr {$A(0,1) + (2 * $X * $Y)}]
		set A(0,2) [expr {$A(0,2) + (2 * $X)}]	        
		set B(0) [expr {$B(0) - ((2 * $X3) + (2 * $X * $Y2))}]
		
        	#Row 1 = G2
		set A(1,0) [expr {$A(1,0) + (2 * $X * $Y)}]
		set A(1,1) [expr {$A(1,1) + (2 * $Y2)}]
		set A(1,2) [expr {$A(1,2) + (2 * $Y)}]
		set B(1)   [expr {$B(1) - ((2 * $Y3) + (2 * $X2 * $Y))}]

		#Row 2 = G3
		set A(2,0) [expr {$A(2,0) + (2 * $X)}]
		set A(2,1) [expr {$A(2,1) + (2 * $Y)}]
		set A(2,2) [expr {$A(2,2) + 2}]
		set B(2)   [expr {$B(2) - ((2 * $Y2) + (2 * $X2))}]
	} 
		

	#LU Decomposition as in OpenCV 
	for {set i 0} {$i <= 1} {incr i} {
		 for {set k [expr {$i + 1}]} {$k <= 2} {incr k} { 
			set temp [expr {double($A($k,$i)) / double($A($i,$i))}] 
				for {set l [expr {$i + 1}]} {$l <= 2} {incr l} {
					set A($k,$l) [expr {$A($k,$l) - ($A($i,$l) * $temp)}] }
					set B($k) [expr {$B($k) - (($B($i)) * $temp)}] 
				} 
		} 
		set B(2) [expr {$B(2) / $A(2,2)}] 
		for {set i 1} {$i >= 0} {incr i -1} {
			for {set k [expr {$i + 1}]} {$k <= 2} {incr k} {
				set B($i) [expr {$B($i) - $A($i,$k) * $B($k)}] 
			} 
			set B($i) [expr {$B($i) / $A($i,$i)}] 
		} 
		
	## Calculate the center and radius of the circle 
	set centerX [expr {int(floor (-(0.5 * $B(0))))}] 
	set centerY [expr {int(floor (-(0.5 * $B(1))))}] 
	set radius  [expr {int(floor (sqrt((pow($B(0),2) + pow($B(1),2)) / 4 - $B(2))))}] 
	puts "Rounded OFF Values:  Center @ ($centerX,$centerY) rad : $radius"
	return [list $centerX $centerY $radius] 	
}

#generate the best fit circle
proc generate {} {
	global selectedItems point
	#list empty or data poits less than 4
 	if {[llength $selectedItems] < 4} { 
		puts "empty list"
		set button \
        		[tk_messageBox \
               		-icon info \
               		-type ok \
               		-title Message \
               		-parent . \
               		-message "Select more data points..."]		
		return 
	}

	
	#if the list was not empty start 
	#call the best fit circle fn 
	#and then draw the circle	
	set circleObject [calc_circle $selectedItems $point]
	draw_circle $circleObject
}



#run the grid creation fn
createGrid


#clear the canvas and selected points list
proc clear {} {
    global mycanvas selectedItems
      
    foreach i $selectedItems { 
    		$mycanvas itemconfigure $i -fill gray     	
    	}
    set selectedItems [list]
    $mycanvas delete CIRCLE
}


# # ## ### ##### ######## ############# #####################
## Invoke event loop.

vwait __forever__
exit

