import gab.opencv.*;
import org.opencv.aruco.*;
import org.opencv.core.*;
import org.opencv.imgproc.Imgproc;
import processing.video.*;
import java.util.List;
import java.util.ArrayList;

Capture video;
OpenCV opencv;

// Liste des IDs de tags ArUco que vous souhaitez détecter
int[] tagsToDetect = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 21, 22, 23}; // Modifiez cette liste selon vos besoins

void setup() {
  fullScreen(); // Met la fenêtre en plein écran
  printArray(Capture.list());

  // Initialise la capture vidéo avec la résolution désirée
  // La librairie Vidéo de processing semble mal gérer autre chose que le YUY
  // La camera fonctionne à des résolutions plus importantes en MJPEG
  // Voir issue https://github.com/processing/processing-video/issues/92
  // Solution utiliser une pipeline gstreamer. 
  // Dans le terminal :
  // gst-launch-1.0 v4l2src ! 'image/jpeg,width=1280,height=720,framerate=30/1' ! jpegdec ! videoconvert ! autovideosink
  // Permet de vérifier que la camera s'affiche correctement.
  // On en sort la déclaration suivante :
  video = new Capture(this, 1280, 720, "pipeline:v4l2src ! image/jpeg,width=1280,height=720,framerate=30/1 ! jpegdec ! videoconvert ");
  opencv = new OpenCV(this, 1280, 720);

  video.start();
}

void draw() {
  if (video.available()) {
    video.read();
  }
  
  // Calculez le rapport d'aspect de la vidéo et de l'écran
  float rapportVideo = 1280 / 720.0;
  float rapportEcran = (float) width / height;
  int newWidth, newHeight;
  
  // Ajustez la taille de l'affichage de la vidéo pour conserver le rapport d'aspect
  if (rapportEcran > rapportVideo) {
    // L'écran est plus large que la vidéo
    newHeight = height;
    newWidth = int(newHeight * rapportVideo);
  } else {
    // L'écran est plus haut que la vidéo
    newWidth = width;
    newHeight = int(newWidth / rapportVideo);
  }

  // Centre l'image dans l'écran
  int x = (width - newWidth) / 2;
  int y = (height - newHeight) / 2;

  // Affiche la vidéo ajustée sans changer son rapport d'aspect
  image(video, x, y, newWidth, newHeight);

  opencv.loadImage(video);

  Mat gray = opencv.getGray();

  // Utiliser des marqueurs ArUco de type 4x4
  Dictionary dictionary = Aruco.getPredefinedDictionary(Aruco.DICT_4X4_50);
  MatOfInt markersIds = new MatOfInt();
  List<Mat> markersCorners = new ArrayList<>();
  DetectorParameters parameters = DetectorParameters.create();

  Aruco.detectMarkers(gray, dictionary, markersCorners, markersIds, parameters);

  // Convertir MatOfInt en ArrayList pour une manipulation facile
  ArrayList<Integer> idsList = new ArrayList<Integer>();
  if (markersIds.rows() > 0) {
    for (int i = 0; i < markersIds.rows(); i++) {
      idsList.add((int)markersIds.get(i, 0)[0]);
    }
  }

  float facteurEchelleX = (float)newWidth / 1280;
float facteurEchelleY = (float)newHeight / 720;

stroke(0, 255, 0); // Couleur verte pour le cadre
noFill(); // Pas de remplissage pour le cadre

for (int i = 0; i < markersCorners.size(); i++) {
  int id = idsList.get(i);
  if (isTagToDetect(id)) {
    Mat corner = markersCorners.get(i);
    float[] points = new float[(int) corner.total() * 2];
    corner.get(0, 0, points);

    beginShape();
    for (int j = 0; j < points.length; j += 2) {
      // Ajustez les points en appliquant le facteur d'échelle et les décalages
      vertex(x + points[j] * facteurEchelleX, y + points[j + 1] * facteurEchelleY);
    }
    endShape(CLOSE);

    // Ajustez également le centre du tag pour l'affichage du texte
    float centerX = 0;
    float centerY = 0;
    for (int j = 0; j < points.length; j += 2) {
      centerX += points[j];
      centerY += points[j + 1];
    }
    centerX = x + (centerX / 4) * facteurEchelleX;
    centerY = y + (centerY / 4) * facteurEchelleY;

    fill(0, 255, 0); // Couleur verte pour le texte
    textSize(20);
    textAlign(CENTER, CENTER);
    text("ID: " + id + "\nPos: (" + (int)centerX + "," + (int)centerY + ")", centerX, centerY);
    noFill(); // Réinitialiser pour les cadres suivants
  }
}
}

// Fonction pour vérifier si un tag spécifique doit être détecté
boolean isTagToDetect(int id) {
  for (int tagId : tagsToDetect) {
    if (id == tagId) {
      return true;
    }
  }
  return false;
}

void captureEvent(Capture c) {
  c.read();
}
