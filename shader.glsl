//raymarcher
const float MAX_DIST = 20.0;
const int STEPS = 150;

//background
const vec3 BACKGROUND = vec3(0.15, 0.35, 1.0);
const float BACKGROUND_LIGHT_INTENSITY = 0.1;

//light
const float RADIUS_OF_LIGHT = 3.0;

//mouse
const float RADIUS_MOUSE = 2.0;

//other data
const float PI = 3.141592;
const float ZOOM = 1.0;

//plan
const vec3 COLOR_P = vec3(0.25, 0.45, 0.5);
const vec3 POS_P = vec3(0.0);
const vec3 NORMALE_P = normalize(vec3(0, 1.0, 0));

//blue ball
const vec3 COLOR_S1 = vec3(0.06, 0.04, 1);
const vec3 POS_S1 = vec3(0.0);
const float SIZE_S1 = 0.5;

//red ball
const vec3 COLOR_S2 = vec3(0.3, 0.04, 0.06);
const vec3 POS_S2 = vec3(0.1, 0.45, -0.1);
const float SIZE_S2 = 0.2;

//yellow torus
const vec3 COLOR_T = vec3(1.0, 0.4, 0.0);
const vec3 POS_T = vec3(0.0, 0.2, 0.1);
const vec3 ROT_T = normalize(vec3(0.0, 0.2, 0.5));
const float RAY_T = 0.8;
const float THICKNESS_T = 0.1;

//orange cylinder
const vec3 COLOR_C = vec3(1.0, 0.2, 0.1);
const vec3 POS_C = vec3(0.6, 0.3, 0.4);
const vec3 ROT_C = vec3(0.1, 0.4, 0.3);
const vec2 SIZE_C = vec2(0.12, 0.4);
const float SMOOTH_C = 0.30;

//pink box
const vec3 COLOR_B = vec3(0.96, 0.41, 0.6);
const vec3 POS_B = vec3(-0.65, 0.5, 0.0);
const vec3 ROT_B = vec3(0.0, 0.5, 0.2);
const vec3 SIZE_B = vec3(0.2);
const float SMOOTH_B = 0.05;

//fonction de rotation
vec3 rotateX(vec3 p, float a){
  float sa = sin(a), ca = cos(a);
  return vec3(p.x, ca * p.y - sa * p.z, sa * p.y + ca * p.z);
}
vec3 rotateY(vec3 p, float a){
  float sa = sin(a),   ca = cos(a);
  return vec3(ca * p.x + sa * p.z, p.y, -sa * p.x + ca * p.z);
}
vec3 rotateZ(vec3 p, float a){
  float sa = sin(a),   ca = cos(a);
  return vec3(ca * p.x - sa * p.y, sa * p.x + ca * p.y, p.z);
}

vec3 rotate(vec3 p, vec3 a){
    p = rotateX(p, a.x);
    p = rotateY(p, a.y);
    p = rotateZ(p, a.z);
    return p;
}


//signed function field
vec4 Plane(vec3 p, vec3 n, vec3 c){
    return vec4(c, dot(p, n));
}

vec4 Sphere(vec3 p, float r, vec3 c){
    return vec4(c, length(p) - r); //rgb=>color, a=>distance
}

vec4 Torus(vec3 p, vec3 rot, float r, float t, vec3 c){
    p = rotate(p, rot);
    return vec4(c, length(vec2(length(p.xz)-r, p.y)) - t);
}

vec4 Cylender(vec3 p, vec3 rot, vec2 size, float smoo, vec3 c){
    p = rotate(p, rot);

    float dX = length(p.xz) - size.x;
    float dY = abs(p.y) - size.y;
    
    float dE = length(vec2(max(dX, 0.0), max(dY, 0.0)));
    float dI = min(max(dX, dY), 0.0);
    
    float d = dE + dI;

    return vec4(c, d - smoo * 0.1);
}

vec4 Box(vec3 p, vec3 rot, vec3 size, float smoo, vec3 c){
    p = rotate(p, rot);
    
    vec3 diff = abs(p) - size;
    
    float dE = length(max(diff, 0.0));
    float dI = min(max(diff.x, max(diff.y, diff.z)), 0.0);
    
    float d = dE + dI;

    return vec4(c, d - smoo * 0.1);
}

vec4 substract(vec4 obj1, vec4 obj2){
    return max(obj1, -obj2);
}

vec4 intersection(vec4 obj1, vec4 obj2){
    return max(obj1, obj2);
}

vec4 minDist(vec4 a, vec4 b){
    return a.a < b.a ? a : b;
}


//calculate the min distance object
vec4 scene(vec3 p){
    vec4 P = Plane(p - POS_P, NORMALE_P, COLOR_P);
    vec4 obj = P;
    
    vec4 S1 = Sphere(p - POS_S1, SIZE_S1, COLOR_S1);
    vec4 S2 = Sphere(p - POS_S2, SIZE_S2, COLOR_S2);
    S1 = substract(S1, S2);
    obj = minDist(obj, S1);
    
    vec4 T = Torus(p - POS_T, ROT_T, RAY_T, THICKNESS_T, COLOR_T);
    obj = minDist(obj, T);
    
    vec4 C = Cylender(p - POS_C, ROT_C, SIZE_C, SMOOTH_C, COLOR_C);
    obj = minDist(obj, C);
    
    vec4 B = Box(p - POS_B, ROT_B, SIZE_B, SMOOTH_B, COLOR_B);
    obj = minDist(obj, B);
    
    return obj;
}

//raymarching
vec4 march(vec3 rO, vec3 rD){
    vec3 cP = rO; //current point
    float d = 0.0;
    vec4 s = vec4(0.0);
    
    for(int i = 0; i < STEPS; i++){
        cP = rO + rD * d;
        s = scene(cP);
        d += s.a;
        if(s.a < 0.001){
            break;
        }
        if(d > MAX_DIST){
            s.rgb = BACKGROUND;
            break;
        }
    }
    s.a = d;
    return s;
}

//calulate the normale of a pixel
vec3 normal(vec3 p){
    float dP = scene(p).a;
    vec2 eps = vec2(0.01, 0.0);
    
    float dX = scene(p + eps.xyy).a - dP; //diff of distance between p and the pts at 0.01x next
    float dY = scene(p + eps.yxy).a - dP; //diff of distance between p and the pts at 0.01y next
    float dZ = scene(p + eps.yyx).a - dP; //diff of distance between p and the pts at 0.01z next
    
    return normalize(vec3(dX, dY, dZ));
}

float lighting(vec3 p, vec3 n){
    vec3 lP = vec3(cos(iTime) * RADIUS_OF_LIGHT, 1.0, sin(iTime) * RADIUS_OF_LIGHT); //position de la lumiere
    vec3 lD = lP - p; //direction of the light
    vec3 lN = normalize(lD); //direction normalize
    
    if(march(p + n * 0.01, lN).a < length(lD)) // if the distance is bigger than the norme of the direction (if it's the background)
        return 0.0; //no lighting
    
    return max(0.0, dot(n, lN)); //else we return the dot product between the normale and the direction of the light form of nb positive
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - (iResolution.xy * 0.5)) / iResolution.y;
    
    vec2 mouse = iMouse.xy / iResolution.xy;
    
    float initAngle = -(PI * 0.5);
    
    vec3 rO = vec3(cos(mouse.x * 3.0 * PI + initAngle) * RADIUS_MOUSE, tan(mouse.y * PI * 0.4 + 0.1), sin(mouse.x * 3.0 * PI + initAngle) * RADIUS_MOUSE);
    vec3 target = vec3(0, 0, 0);
    
    vec3 fwd = normalize(target - rO); //vector foreward
    vec3 side = normalize(cross(vec3(0, 1.0, 0), fwd)); //cross product => return a vector perpendicular at two vectors
    vec3 up = normalize(cross(fwd, side));
    
    vec3 rD = normalize(ZOOM * fwd + side * uv.x + up * uv.y); //vector where the camera is pointing
    
    
    vec4 s = march(rO, rD); //raymarching, rgb=>color, a=> distance
    float d = s.a; //distance
    vec3 col = mix(vec3(1.0), BACKGROUND, pow(uv.y + 0.5, 0.6 + mouse.y)); //linear interpollation between white and the background color in terms of uv.y
    
    if(d < MAX_DIST){
        vec3 p = rO + rD * d; //pts touch
    
        col = s.rgb;
        vec3 nor = normal(p);
        float l = lighting(p, nor);
        
        vec3 amb_backg = nor.y * BACKGROUND * BACKGROUND_LIGHT_INTENSITY;
    
        col *= (l + amb_backg);
        col = pow(col, vec3(0.4545)); //gamma curve correction

    }
    
    fragColor = vec4(col.rgb, 1.0);
}
