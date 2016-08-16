// dejaVu
// Author: David Montero - October 2012
// javacvPro library from X. HINAULT


import ipcapture.*; // Librería para captura de vídeo sobre IP
import processing.video.*;
import monclubelec.javacvPro.*;
import ddf.minim.*; // Librería de audio


int FPS = 10; // Marcos por segundo
int COLUMNS = 3;
int ROWS = 2;
int NROOMS= COLUMNS*ROWS;  // constante definiendo el número de habitaciones (vídeos)

// Poner a "false" para tener la imágen a color
boolean BW = true;


Minim minim; // Clase para reproducir audio
AudioPlayer audio; // Reproductor de audio

IPCapture cam;
//Capture cam;     // clase Capture para coger la imágen de la cámara 

Movie[] roomBkg = new Movie[NROOMS];  // Vídeos para los fondos

OpenCV opencv;  // Librería de visión artificial

// Resolución de captura de vídeo, IMPORTANTE: Tiene que ser la misma que la de los ficheros de video
int widthCapture=640;
int heightCapture=480;

// Resolucion de la imagen que se muestra en pantalla
int widthImg = widthCapture/2;
int heightImg = heightCapture/2;

// Parámetros para el algoritmo de eliminación de fondo
// default : history = 16; varThreshold = 16, bShadowDetection= true
int threshold = 16;
int history = 1000;
boolean bShadowDetection = true;

// Fuente para el timetag
PFont font;
String timetag;
// Tamaño de la fuente
int fontSize = 20;

void setup() { 
   frame.removeNotify(); 
  // Eliminamos el marco de la ventana
  frame.setUndecorated(true);
  size(widthImg*COLUMNS, heightImg*ROWS);  
  // Ponemos el fondo a negro
  background(0);
  // Ajustamos la frecuencia de refresco
  frameRate(FPS);

  // Cargamos la fuente
  font = loadFont("Monospaced-48.vlw");
  textFont(font, fontSize);
  
  // Inicializamos la cámara
  // Poner aquí la URL el username y el password the la cámara, si no tiene username ni password símplemente escribir "" (dobles comillas)
  cam = new IPCapture(this, "http://10.64.123.200:80/video1.mjpg", "username", "password");
  //cam = new Capture(this, widthCapture, heightCapture);  
  cam.start();  

  // Inicializamos el reproductor de audio con el fichero audio.mp3 de la carpeta data/
  minim = new Minim(this);
  audio = minim.loadFile("data/audio.mp3", 2048);
  audio.play();
  audio.loop(); // comienza a reproducir el audio en bucle

  // Initializar los videos de las habitaciones, los ficheros se tienen que llamar room_numero.ogg y estar en la carpeta data/
  for (int i=0; i<NROOMS;i++) {
    roomBkg[i] = new Movie(this, "room_"+i+".ogg");
    roomBkg[i].loop();  // comienza a reproducir los vídeos en bucle
  }

  opencv = new OpenCV(this); // Inicialización de los objetos OpenCV (librería javacvPro : tratamiento de imagen y reconocimiento visual) 
  opencv.allocate(widthCapture, heightCapture); // Crear el buffer para las imágenes procesadas por OpenCV

  //--- Initialización del objeto MOG que nos permite eliminar el fondo
  opencv.bgsMOG2Init(history, threshold, bShadowDetection); 

  // Definimos el tamaño de la pantalla para albergar 2x3 vídeos
//  size(opencv.width()*COLUMNS, opencv.height()*ROWS);
}


void  draw() { 
  PImage diff=new PImage(widthCapture, heightCapture); // Imágen que almacena las partes móviles de la escena (el espectador)
  timetag = year()+"-"+month()+"-"+day()+"  "+hour()+":"+minute()+":"+second();
  if (cam.isAvailable() == true) { // si hay un nuevo marco disponible en la cámara
  //if (cam.available() == true) { // Si hay un nuevo marco disponible en la cámara
    cam.read(); // Leemos el marco
    opencv.copy(cam); // copiamos la imágen en el buffer de OpenCV
    opencv.blur(7); // Le aplicamos un filtro de difusión para suavizar los colores (ayuda a eliminar el ruido en la substracción de fondo)
    opencv.bgsMOG2Apply(opencv.Buffer, opencv.BufferGray, -1); // Eliminamos el fondo
    diff = opencv.getBufferGray();
    for (int i=0; i<NROOMS;i++) { // Creamos las escenas y las mostramos en pantalla para cada uno de los vídeos de fondo
      buildAugment(roomBkg[i], diff, i);
    } // fin if available
  } // fin draw
}

void buildAugment(Movie video, PImage diff, int idx) {
  PImage augmentedFrame=new PImage(widthCapture, heightCapture);
  int frameX = widthImg*(idx%COLUMNS);
  int frameY = heightImg*(idx%ROWS);
  
  if (video.available()) { //Si el fichero de video está disponible
    video.read();// Leemos un marco de la imágen de video
    video.loadPixels(); // Cargamos la información de píxeles del marco
    cam.loadPixels();
    augmentedFrame.loadPixels();
    for (int x=0;x< diff.width;x++) {
      for (int y=0;y< diff.height;y++) {
        int loc = x + y*diff.width;
        if (diff.pixels[loc]!=color(0, 0, 0)) { // Si el píxel no es negro es un sujeto en movimiento (espectador) le asignamos su color original 
          augmentedFrame.pixels[loc]=cam.pixels[loc];
        }
        else { // Si es negro, es el fondo, le asignamos el correspondiente pixel del vídeo de la habitación
          augmentedFrame.pixels[loc]=video.pixels[loc];
        }
      }        
      augmentedFrame.updatePixels();
    }
    if (BW) {
      opencv.copyToGray(augmentedFrame);
      augmentedFrame=opencv.getBufferGray();
    }
    // Reducimos el tamaño de la imagen a mostrar en pantalla
     augmentedFrame.resize(widthImg, heightImg);
    // Mostrar el marco del video
    set(frameX, frameY, augmentedFrame);
    // Imprimir timetag
    text(timetag, frameX+10, frameY+fontSize);
    // Imprimir el número de habitación
    text("SALA "+idx, frameX+10, frameY+fontSize*2);
  }
}

void keyPressed() {    
  if (key==CODED) {
    switch (keyCode)
    {
    case UP:
      threshold++;
      println("Threshold ++ : "+threshold);
      break;
    case DOWN:
      threshold--;
      println("Threshold -- : "+threshold);
      break;
    case LEFT:
      history--;
      println("History -- : "+history);
      break;
    case RIGHT:
      history++;
      println("History ++ : "+history);
      break;
    }
  }
  else {
    if (bShadowDetection) {
      bShadowDetection=false;
      println("Shadow Detection DISABLED");
    }
    else {
      bShadowDetection=true;
      println("Shadow Detection ENABLED");
    }
  }
}

