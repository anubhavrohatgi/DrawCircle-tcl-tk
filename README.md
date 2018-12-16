# DrawCircle-tcl-tk
Draw a circle using tcl/tk. Digitising cirlces


1. Download ActiveTcl-8.6.7 
2. $ tar -xvzf ActiveTcl-8.6.7.0-x86_64-linux-glibc-2.5-404761.tar.gz
3. $ cd ActiveTcl-8.6.7.0-x86_64-linux-glibc-2.5-404761/
4. Just in case the install.sh is not executable then step 5 else skip to 6
5. $ chmod +x install.sh
6. $ ./install.sh
7. Then in order to set the environment paths step 8 -12 are followed
8. $ vim ~/.bashrc
9. press i
10.At the end of the file type the following
	#for tcl/tk
	export PATH="/opt/ActiveTcl-8.6/bin:$PATH"
    
11.The above path is as per my installation path. This may be same or different in
   your environment. Once editing is done. press ESC then shift + ; and type wq to save and quit vim.
12.Now reload these environment paths using:
	$ source .bashrc 
13.After this I played around with some of the demos that were located 2
	$ cd /opt/ActiveTcl-8.6/demos/Tk8.6
14.Ran a few using wish interpreter.
    eg. 	$ wish hello
15. From my researcher acumen, I have referenced documentation from here :
	https://www.tcl.tk/doc/
	http://zetcode.com/lang/tcl/
	http://www.tkdocs.com/
	https://www.tutorialspoint.com/tcl-tk/tk_canvas_rectangle.htm
	http://pages.cpsc.ucalgary.ca/~saul/personal/archives/Tcl-Tk_stuff/tcl_examples/
	https://core.tcl.tk/tklib/doc/trunk/embedded/www/tklib/files/modules/canvas/canvas_epoints.html
	http://www.sciviews.org/recipes/tcltk/TclTk-event-binding/
	http://wiki.tcl.tk/18055
	http://wiki.tcl.tk/884

Improvements

1. I could have redone the architecture of the code with OOPs concepts and thereby improved its efficiency
   and reusability.
2. Would have used a separate class procedure for setup of the canvas and events just like how we call update 
   and event triggers in OpenGL(for example) applications. 
3. OOPs would have completely removed/reduced the use of globals.
4. Currently the code is accepting all sorts of image sizes and grid sizes the only restriction is the n+5 size 
   of the image. This usually gives a better whole no padding between the logical pixels.
5. Since I performed the Problem 2 first, I could not put close event on the widget, which properly terminates the 
   instance on clicking the x button at the top window, though close button in the widget does the same, it would have been
   better if I could put the complete functionality. In 1st problem I have solved this.
6. In the 1st Problem I could have made use of canvas tags more efficienly had I known how to use their inbuilt functions 
   like closest, overlapping etc. But I think I am slightly unclear as to what closest is. I decoded the same functionality to 
   produce nearby points using the equation of the circle.
7. In problem 2, I have used Least Squares mehod to fit points to the circle. For better and optimized performance,
   I could have moved to complex but optimized procedures like Modified Least Squares Fitting, Reduced Least Squares Fitting 	
   and other advanced circular regression techniques.
8. Currently in both my solutions, pixel/grain size is fixed in order to make the code more scalable, like going for 1000x1000 
   scenarios, I need to make this grain size variable and auto-calculative. Both the padding and the grainsize need to be automatically
   calulated. Currently only the padding/splitsize is being calculated automatically. But the catch is if we increase the size of the 
   image enough to support 1000x1000 graininess of 10 grain size, the currect scope of the solution is scalable enough to support the same,
   if this proportion is not correct the padding size is negative(indicates overlapping pixels, which is logically a fail case).


	



