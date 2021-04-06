import java.util.ArrayList;
import java.util.Collections;

//these are variables you should probably leave alone
int index = 0; //starts at zero-ith trial
float border = 0; //some padding from the sides of window
int trialCount = 12; //this will be set higher for the bakeoff
int trialIndex = 0; //what trial are we on
int errorCount = 0;  //used to keep track of errors
float errorPenalty = 0.5f; //for every error, add this value to mean time
int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false; //is the user done

final int screenPPI = 72; //what is the DPI of the screen you are using
//you can test this by drawing a 72x72 pixel rectangle in code, and then confirming with a ruler it is 1x1 inch. 

//These variables are for my example design. Your input code should modify/replace these!

private class Anchor {
  float x = 0;
  float y = 0;
  float z = 10f;
  
  public Anchor(float x, float y, float z) {
    this.x = x;
    this.y = y;
    this.z = z;
  }
  
  public void updatePosition(float x, float y) {
    this.x = x;
    this.y = y;
  }
  
  public void updateSize(float z) {
    this.z = z;
  }
  
  public boolean underMouse() {
    System.out.println(String.format("%.2f,%.2f,%.2f,%.2f,%.2f", this.x, this.y, this.z, adjMouseX(), adjMouseY()));
    return dist(this.x, this.y, adjMouseX(), adjMouseY()) < this.z;
  }
  
  // Assume coordinates have been translated by caller
  public void drawAnchor() {
    noStroke();
    fill(192, 192, 60, 100);
    circle(this.x, this.y, this.z);
  }
}

private class Logo {
  float x = 0;
  float y = 0;
  float z = 50f;
  float rotation = 0;
  
  Anchor centerAnchor;
  Anchor[] cornerAnchors = new Anchor[4];
  Anchor[] rotateAnchors = new Anchor[4];
  
  boolean dragging = false;
  boolean resizing = false;
  boolean rotating = false;
  
  public Logo() {
    float anchorSize = this.z / 4f;
    float anchorShift = this.z / 2f;
    
    // Anchor coordinates should be relative to Logo's center
    
    this.centerAnchor = new Anchor(0, 0, anchorSize);
    
    this.cornerAnchors[0] = new Anchor(-anchorShift, -anchorShift, anchorSize);
    this.cornerAnchors[1] = new Anchor(anchorShift, -anchorShift, anchorSize);
    this.cornerAnchors[2] = new Anchor(-anchorShift, anchorShift, anchorSize);
    this.cornerAnchors[3] = new Anchor(anchorShift, anchorShift, anchorSize);
    
    this.rotateAnchors[0] = new Anchor(0, -anchorShift * 1.5f, anchorSize);
    this.rotateAnchors[1] = new Anchor(anchorShift * 1.5f, 0, anchorSize);
    this.rotateAnchors[2] = new Anchor(0, anchorShift * 1.5f, anchorSize);
    this.rotateAnchors[3] = new Anchor(-anchorShift * 1.5f, 0, anchorSize);
  }
  
  public void drawLogo() {
    pushMatrix();
    translate(width/2 + this.x, height/2 + this.y); // center the screen coords on the logo coords 
    translate(this.x, this.y);
    rotate(radians(this.rotation));
    noStroke();
    fill(60, 60, 192, 192);
    rect(0, 0, this.z, this.z);
    
    this.centerAnchor.drawAnchor();
    for (int i = 0; i < 4; i++) {
      this.cornerAnchors[i].drawAnchor();
      this.rotateAnchors[i].drawAnchor();
    }
    
    popMatrix();
  }
  
  public boolean mouseOverCenter() {
    return this.centerAnchor.underMouse();
  }
  
  public boolean mouseOverCorner() {
    boolean b = false;
    for (int i = 0; i < 4; i++) {
      b = b || this.cornerAnchors[i].underMouse();
    }
    return b;
  }
  
  public boolean mouseOverRotate() {
    boolean b = false;
    for (int i = 0; i < 4; i++) {
      b = b || this.rotateAnchors[i].underMouse();
    }
    return b;
  }
  
  public void moveToMouse() {
    // This doesn't use adjMouseX because otherwise wouldn't move
    // Just adjusts mouse coords repective to center of screen
    // Uses "absolute" positioning (from center)
    this.x = mouseX - width/2;
    this.y = mouseY - height/2;
  }
  
  public void resizeToMouse() {
    this.z = dist(this.x, this.y, adjMouseX(), adjMouseY());
  }
  
  public void rotateToMouse() {
    return;
  }
  
  public void updateFromMouse() {
    if (this.dragging) {
      this.moveToMouse();
      //System.out.println(String.format("(%.2f,%.2f,%.2f)-(%.2f,%.2f,%.2f)", this.x, this.y, this.z, this.centerAnchor.x, this.centerAnchor.y, this.centerAnchor.z));
    } else if (this.resizing) {
      this.resizeToMouse();
    } else if (this.rotating) {
      this.rotateToMouse();
    }
  }
}

private class Destination
{
  float x = 0;
  float y = 0;
  float rotation = 0;
  float z = 0;
}

ArrayList<Destination> destinations = new ArrayList<Destination>();

Logo logo = new Logo();

void setup() {
  size(1000, 800);  
  rectMode(CENTER);
  ellipseMode(CENTER);
  textFont(createFont("Arial", inchToPix(.3f))); //sets the font to Arial that is 0.3" tall
  textAlign(CENTER);

  //don't change this! 
  border = inchToPix(2f); //padding of 1.0 inches

  for (int i=0; i<trialCount; i++) //don't change this! 
  {
    Destination d = new Destination();
    d.x = random(-width/2+border, width/2-border); //set a random x with some padding
    d.y = random(-height/2+border, height/2-border); //set a random y with some padding
    d.rotation = random(0, 360); //random rotation between 0 and 360
    int j = (int)random(20);
    d.z = ((j%12)+1)*inchToPix(.25f); //increasing size from .25 up to 3.0" 
    destinations.add(d);
    println("created target with " + d.x + "," + d.y + "," + d.rotation + "," + d.z);
  }

  Collections.shuffle(destinations); // randomize the order of the button; don't change this.
}



void draw() {

  background(40); //background is dark grey
  fill(200);
  noStroke();

  //shouldn't really modify this printout code unless there is a really good reason to
  if (userDone)
  {
    text("User completed " + trialCount + " trials", width/2, inchToPix(.4f));
    text("User had " + errorCount + " error(s)", width/2, inchToPix(.4f)*2);
    text("User took " + (finishTime-startTime)/1000f/trialCount + " sec per destination", width/2, inchToPix(.4f)*3);
    text("User took " + ((finishTime-startTime)/1000f/trialCount+(errorCount*errorPenalty)) + " sec per destination inc. penalty", width/2, inchToPix(.4f)*4);
    return;
  }

  //===========DRAW DESTINATION SQUARES=================
  for (int i=trialIndex; i<trialCount; i++) // reduces over time
  {
    pushMatrix();
    translate(width/2, height/2); //center the drawing coordinates to the center of the screen
    Destination d = destinations.get(i);
    translate(d.x, d.y); //center the drawing coordinates to the center of the screen
    rotate(radians(d.rotation));
    noFill();
    strokeWeight(3f);
    if (trialIndex==i)
      stroke(255, 0, 0, 192); //set color to semi translucent
    else
      stroke(128, 128, 128, 128); //set color to semi translucent
    rect(0, 0, d.z, d.z);
    popMatrix();
  }

  logo.updateFromMouse();

  //===========DRAW LOGO SQUARE=================
  logo.drawLogo();

  //===========DRAW EXAMPLE CONTROLS=================
  fill(255);
  scaffoldControlLogic(); //you are going to want to replace this!
  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, inchToPix(.8f));
}

//my example design for control, which is terrible
void scaffoldControlLogic()
{
  ////upper left corner, rotate counterclockwise
  //text("CCW", inchToPix(.4f), inchToPix(.4f));
  //if (mousePressed && dist(0, 0, mouseX, mouseY)<inchToPix(.8f))
  //  logoRotation--;

  ////upper right corner, rotate clockwise
  //text("CW", width-inchToPix(.4f), inchToPix(.4f));
  //if (mousePressed && dist(width, 0, mouseX, mouseY)<inchToPix(.8f))
  //  logoRotation++;

  ////lower left corner, decrease Z
  //text("-", inchToPix(.4f), height-inchToPix(.4f));
  //if (mousePressed && dist(0, height, mouseX, mouseY)<inchToPix(.8f))
  //  logoZ = constrain(logoZ-inchToPix(.02f), .01, inchToPix(4f)); //leave min and max alone!

  ////lower right corner, increase Z
  //text("+", width-inchToPix(.4f), height-inchToPix(.4f));
  //if (mousePressed && dist(width, height, mouseX, mouseY)<inchToPix(.8f))
  //  logoZ = constrain(logoZ+inchToPix(.02f), .01, inchToPix(4f)); //leave min and max alone! 

  ////left middle, move left
  //text("left", inchToPix(.4f), height/2);
  //if (mousePressed && dist(0, height/2, mouseX, mouseY)<inchToPix(.8f))
  //  logoX-=inchToPix(.02f);

  //text("right", width-inchToPix(.4f), height/2);
  //if (mousePressed && dist(width, height/2, mouseX, mouseY)<inchToPix(.8f))
  //  logoX+=inchToPix(.02f);

  //text("up", width/2, inchToPix(.4f));
  //if (mousePressed && dist(width/2, 0, mouseX, mouseY)<inchToPix(.8f))
  //  logoY-=inchToPix(.02f);

  //text("down", width/2, height-inchToPix(.4f));
  //if (mousePressed && dist(width/2, height, mouseX, mouseY)<inchToPix(.8f))
  //  logoY+=inchToPix(.02f);
}


void mousePressed()
{
  if (startTime == 0) //start time on the instant of the first user click
  {
    startTime = millis();
    println("time started!");
  }
  
  //pushMatrix();
  //translate(width/2, height/2); //center the drawing coordinates to the center of the screen
  //translate(logo.x, logo.y);  // adjust to make center of logo center of coordinates
  
  // If user is pressing close to center of Logo
  if (logo.mouseOverCenter()) {
    logo.dragging = true;
  } else if (logo.mouseOverCorner()) {
    logo.resizing = true;
  } else if (logo.mouseOverRotate()) {
    logo.rotating = true;
  }
  
  //popMatrix();
}


void mouseReleased()
{
  //check to see if user clicked middle of screen within 3 inches, which this code uses as a submit button
  //if (dist(width/2, height/2, mouseX, mouseY)<inchToPix(3f))
  //{
  //  if (userDone==false && !checkForSuccess())
  //    errorCount++;

  //  trialIndex++; //and move on to next trial

  //  if (trialIndex==trialCount && userDone==false)
  //  {
  //    userDone = true;
  //    finishTime = millis();
  //  }
  //}
  
  logo.dragging = false;
  logo.resizing = false;
  logo.rotating = false;
}

public float adjMouseX() {
  return mouseX - width/2 - logo.x;
}

public float adjMouseY() {
  return mouseY - height/2 - logo.y;
}

//probably shouldn't modify this, but email me if you want to for some good reason.
public boolean checkForSuccess()
{
  Destination d = destinations.get(trialIndex);	
  boolean closeDist = dist(d.x, d.y, logo.x, logo.y)<inchToPix(.05f); //has to be within +-0.05"
  boolean closeRotation = calculateDifferenceBetweenAngles(d.rotation, logo.rotation)<=5;
  boolean closeZ = abs(d.z - logo.z)<inchToPix(.05f); //has to be within +-0.05"	

  println("Close Enough Distance: " + closeDist + " (logo X/Y = " + d.x + "/" + d.y + ", destination X/Y = " + logo.x + "/" + logo.y +")");
  println("Close Enough Rotation: " + closeRotation + " (rot dist="+calculateDifferenceBetweenAngles(d.rotation, logo.rotation)+")");
  println("Close Enough Z: " +  closeZ + " (logo Z = " + d.z + ", destination Z = " + logo.z +")");
  println("Close enough all: " + (closeDist && closeRotation && closeZ));

  return closeDist && closeRotation && closeZ;
}

//utility function I include to calc diference between two angles
double calculateDifferenceBetweenAngles(float a1, float a2)
{
  double diff=abs(a1-a2);
  diff%=90;
  if (diff>45)
    return 90-diff;
  else
    return diff;
}

//utility function to convert inches into pixels based on screen PPI
float inchToPix(float inch)
{
  return inch*screenPPI;
}
