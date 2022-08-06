import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.UUID;

Game game = new Game(new Resolution(720, 1280), 0x0a0a0a, States.INGAME);

void settings() {
  game.settings();
}

void setup() {
  game.setup();
}

void draw() {
  game.draw();
} 

void keyTyped() {
  game.keyTyped();
}

void keyReleased() {
  game.keyReleased();
}

enum States {
  MENU,
  SELECT,
  INGAME,
  GAMEOVER
}
/*
static class Entities {
public Entity TEST_ENTITY = new Entity(new Sprite("assets/texture/entity/place_holder.png", new Resolution(200, 200)), new Location(50.0f, 50.0f));
}
*/
class Game {
  
  private Resolution res;
  private int bgcolor;
  private States states;
  private int tick;
  private int judgeFlag = 0b000;
  private String judge = "";
  private int judgeTime = 0;
  private int point = 0;
  private PImage judgePointSprite; 
  private Column[] columns = {
    new Column(200.0f),
      new Column(400.0f),
      new Column(600.0f),
    };
  private JudgePoint[] judgePoints = {
    new JudgePoint(new Location(columns[0].getCenter(), 1000.0f)),
      new JudgePoint(new Location(columns[1].getCenter(), 1000.0f)),
      new JudgePoint(new Location(columns[2].getCenter(), 1000.0f))
    };
  
  public Game(Resolution res, int bgcolor, States initialState) {
    this.res = res;
    this.bgcolor = bgcolor;
    this.states = initialState;
  }
  
  void setupScore() {
    ScoreManager.addNoteInfos(
      new NoteInfo(10, columns[1]),
      new NoteInfo(30, columns[0]),
      new NoteInfo(50, columns[2]),
      new NoteInfo(80, columns[2]),
      new NoteInfo(80, columns[1]),
      new NoteInfo(120, columns[2]),
      new NoteInfo(150, columns[1]),
      new NoteInfo(150, columns[0]),
      new NoteInfo(180, columns[2]),
      new NoteInfo(185, columns[1]),
      new NoteInfo(200, columns[0]),
      new NoteInfo(210, columns[1]),
      new NoteInfo(220, columns[2]),
      new NoteInfo(250, columns[1])
     );
  }
  
  void settings() {
    size(res.getWidth(), res.getHeight());
  }
  
  void setup() {
    setupScore();
    judgePointSprite = loadImage("assets/texture/judge.png");
    JudgePoints.addJudgePoints(
      judgePoints[0],
      judgePoints[1],
      judgePoints[2]
     );
  }
  
  void draw() {
    background(bgcolor);
    imageMode(CENTER);
    JudgePoints.getPoints().forEach((p) -> {
      image(judgePointSprite, p.getLocation().getX(), p.getLocation().getY(), 128, 128);
    });
    if ((judgeFlag & 0b100) > 0) {
      rect(judgePoints[0].getLocation().getX() - 20, 0, 40, res.getHeight());
    }
    if ((judgeFlag & 0b010) > 0) {
      rect(judgePoints[1].getLocation().getX() - 20, 0, 40, res.getHeight());
    }
    if ((judgeFlag & 0b001) > 0) {
      rect(judgePoints[2].getLocation().getX() - 20, 0, 40, res.getHeight());
    }
    switch(states) {
      case INGAME :
        textSize(64);
        textAlign(CENTER);
        text(judge, res.getWidth() / 2, res.getHeight() / 2);
        ScoreManager.getNoteInfos().forEach((info) -> {
          if (info.getTick() == TickManager.now()) {
            EntityManager.spawnEntity(new NoteEntity(new Sprite("assets/texture/entity/note.png", new Resolution(64, 64)), 10.0f, info.getColumn(), NoteTypes.SINGLE));
          }
        });
        EntityManager.getAll().forEach((key, ent) -> {
          ent.draw();
          ent.update();
          if (ent.getLocation().getY() > res.getHeight()) EntityManager.addQueue(ent);
        });
        EntityManager.doQueue();
        textAlign(LEFT);
        textSize(25);
        text(String.format("tick:%02d(%d)", TickManager.now() % 30, TickManager.now()), 20, 40);
        text(String.format("score:%06d", point), 20, 85);
        break;
      default : break;
    }
    if ((TickManager.now() - judgeTime) > 20) {
      judge = "";
    }
    TickManager.next();
  }
  
  void keyTyped() {
    EntityManager.getAll().forEach((k, v) -> {
      JudgePoint targetPoint = null;
      if (key == 'f') {
        targetPoint = judgePoints[0];
        judgeFlag |= 0b100;
      } 
      if (key == 'g') {
        targetPoint = judgePoints[1];
        judgeFlag |= 0b010;
      }
      if (key == 'h') {
        targetPoint = judgePoints[2];
        judgeFlag |= 0b001;
      }
      if (targetPoint != null) {
        double diff = LocationUtil.diff(v.getLocation(), targetPoint.getLocation());
        if(diff < 200) { // BAD
          if(v.getLocation().getX() == targetPoint.getLocation().getX()) {
            if(diff < 150 && diff >= 100) { // GOOD
              point += 50;
              judge = "NICE +50";
            }
            else if (diff < 100 && diff >= 50) { // GREAT
              point += 80;
              judge = "GREAT +80";
            }
            else if (diff < 50) { // PERFECT
              point += 120;
              judge = "EXACT +120";
            }
            else {
              point += 20;
              judge = "BAD +20";
            }
            judgeTime = TickManager.now();
            EntityManager.addQueue(v);
          }
        }
      }
    });
    EntityManager.doQueue();
  }
  
  void keyReleased() {
    judgeFlag = 0b000;
  }
  
  void changeState(States to) {
    this.states = to;
  }
  
}

class Resolution {
  
  private Map<String, Integer> _res = new HashMap<>();
  
  public Resolution(int width, int height) {
    _res.put("w", width); _res.put("h", height); 
  }
  
  public int getWidth() {
    return _res.get("w");
  }
  
  public int getHeight() {
    return _res.get("h");
  }
  
}

static class LocationUtil {
  public static boolean same(Location loc1, Location loc2) {
    if (loc1.getX() == loc2.getX() && loc1.getY() == loc2.getY()) return true;
    return false;
  }
  
  public static double diff(Location loc1, Location loc2) {
    float x1 = Math.min(loc1.getX(), loc2.getX());
    float x2 = Math.max(loc1.getX(), loc2.getX());
    float y1 = Math.min(loc1.getY(), loc2.getY());
    float y2 = Math.max(loc1.getY(), loc2.getY());
    return Math.sqrt(Math.pow((x2 - x1), 2) + Math.pow((y2 - y1), 2));
  }
}

class Location {
  private Map<String, Float> _loc = new HashMap<>();
  
  public Location(float x, float y) {
    _loc.put("x", x); _loc.put("y", y);
  }
  
  public float getX() {
    return _loc.get("x");
  }
  
  public float getY() {
    return _loc.get("y");
  }
  
  public void setX(float x) {
    _loc.replace("x", x);
  }
  
  public void setY(float y) {
    _loc.replace("y", y);
  }
  
  public void set(float x, float y) {
    _loc.replace("x", x); _loc.replace("y", y);
  }
}

class JudgePoint {
  private Location _loc;
  
  public JudgePoint(Location loc) {
    _loc = loc;
  }
  
  public Location getLocation() {
    return _loc;
  }
}

static class JudgePoints {
  private static List<JudgePoint> _points = new ArrayList<>();
  
  public static void addJudgePoint(JudgePoint point) {
    _points.add(point);
  }
  
  public static void addJudgePoints(JudgePoint...points) {
    Arrays.stream(points).forEach((point) -> {
      _points.add(point);
    });
  }
  
  public static List<JudgePoint> getPoints() {
    return _points;
  }
  
  public static JudgePoint getPoint(int index) {
    return _points.get(index);
  }
  
  public static NoteEntity getNearestNote() {
    return null;
  }
}

class Column {
  private float _center;
  
  public Column(float center) {
    _center = center;
  }
  
  public float getCenter() {
    return _center;
  }
}

class Sprite {
  private String _path;
  private PImage _spriteImage;
  private Resolution _size;
  
  public Sprite(String path, Resolution size) { 
    _path = path;
    _size = size;
    
    _spriteImage = loadImage(_path);
    _spriteImage.resize(_size.getWidth(), _size.getHeight());
  }
  
  public PImage get() {
    return _spriteImage;
  } 
  
  public void resize(Resolution to) {
    _size = to;
    _spriteImage.resize(_size.getWidth(), _size.getHeight());
  }
}

protected class EntityBase {
  Location _location;
  Sprite _sprite;
  UUID _uuid;
  
  public EntityBase(Sprite sprite, Location initialLocation) {
    _location = initialLocation;
    _uuid = UUID.randomUUID();
    _sprite = sprite;
  }
  
  public String getType() {
    return "entity_base";
  }
  
  public Location getLocation() {
    return _location;
  }
  
  public void setLocation(float x, float y) {
    _location.set(x, y);
  }
  
  public void setLocation(Location locIn) {
    _location = locIn;
  }
  
  public Sprite getSprite() {
    return _sprite;
  }
  
  public void setSprite(Sprite spriteIn) {
    _sprite = spriteIn;
  }
  
  public void setUUID(UUID uuid) {
    _uuid = uuid;
  }
  
  public UUID getUUID() {
    return _uuid;
  }
  
  public String getKey() {
    return String.format("%s+%s", this.getType(), _uuid);
  }
  
  public void draw() {
    image(_sprite.get(), _location.getX(), _location.getY());
  }
  
  public void update() {
    
  }
}

enum NoteTypes {
  SINGLE,
  LONG,
  HOLD
}

class NoteEntity extends EntityBase {
  private Column _column;
  private NoteTypes _type;
  
  public NoteEntity(Sprite sprite, float y, Column column, NoteTypes type) {
    super(sprite, new Location(column.getCenter(), y));
  }
  
  public Column getColumn() {
    return _column;
  }
  
  public NoteTypes getNoteType() {
    return _type;
  }
  
  @Override
  public String getType() {
    return "note_entity";
  }
  
  @Override
  public void update() {
    _location.setY(_location.getY() + 12.0f);
  }
}

public static class TickManager {
  private static int _tick;
  public static void next() {
    _tick += 1;
  }
  
  public static int now() {
    return _tick;
  }
}

public class NoteInfo {
  private int _tick;
  private Column _column;
  
  public NoteInfo(int tick, Column column) {
    _tick = tick;
    _column = column;
  }
  
  public int getTick() {
    return _tick;
  }
  
  public Column getColumn() {
    return _column;
  }
}

public static class ScoreManager {
  private static final List<NoteInfo> _infos = new ArrayList<>();
  
  public static void addNoteInfo(NoteInfo info) {
    _infos.add(info);
  }
  
  public static void addNoteInfos(NoteInfo...infos) {
    Arrays.stream(infos).forEach((info) -> {
      _infos.add(info);
    });
  }
  
  public static List<NoteInfo> getNoteInfos() {
    return _infos;
  }
}

public static class EntityManager {
  private static Map<String, EntityBase> _entities = new HashMap<>();
  private static List<EntityBase> _queue = new ArrayList<>();
  
  public static Map<String, EntityBase> getAll() {
    return _entities;
  }
  
  public static void spawnEntity(EntityBase entity) {
    _entities.put(entity.getKey(), entity);
  }
  
  public static void spawnEntities(EntityBase...entities) {
    Arrays.stream(entities).forEach((entity) -> {
      _entities.put(entity.getKey(), entity);
    });
  }
  
  public static void killEntity(EntityBase target) {
    _entities.remove(target.getKey());
  }
  
  public static void killEntities(EntityBase...targets) {
    Arrays.stream(targets).forEach((entity) -> {
      _entities.remove(entity.getKey());
    });
  }
  
  public static void killAll() {
    _entities = new HashMap<>();
  }
  
  public static void addQueue(EntityBase entity) {
    _queue.add(entity);
  }
  
  public static void doQueue() {
    _queue.forEach((ent) -> {
      killEntity(ent);
    });
    _queue.clear();
  }
}

class Graphic {
  
}
