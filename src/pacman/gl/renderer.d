module pacman.gl.renderer;

import std.experimental.logger;
import std.file;
import std.string;

import gfm.math: radians;
import gfm.opengl;

import pacman.gl.texture;
import pacman.globals;
import pacman;

struct Vertex
{
    vec2f coordinate;
    vec2f textureCoordinate;
}

class Renderer
{
    private GLProgram _program;
    private GLBuffer buffer;
    private VertexSpecification!Vertex specification;
    private bool firstUpdate = true;
    private mat4 view;
    private mat4 projection;
    
    this()
    {
        {
            auto vertexShaderSource = read_lines("res/shader.vs");
            auto fragmentShaderSource = read_lines("res/shader.fs");
            
            info("Loading vertex shader");
            
            auto vertexShader = new GLShader(opengl, GL_VERTEX_SHADER, vertexShaderSource);
            scope(exit) vertexShader.destroy;
            
            info("Loading fragment shader");
            
            auto fragmentShader = new GLShader(opengl, GL_FRAGMENT_SHADER, fragmentShaderSource);
            scope(exit) fragmentShader.destroy;
            _program = new GLProgram(opengl, [vertexShader, fragmentShader]);
            
            _program.link;
            _program.use;
        }
        
        {
            enum float vertexMin = 0;
            enum float vertexMax = 1;
            enum float uvMin = 0;
            enum float uvMax = 1;
            
            immutable shape = [
                Vertex(
                    vec2f(vertexMin, vertexMax),
                    vec2f(uvMin, uvMax)
                ),
                Vertex(
                    vec2f(vertexMax, vertexMax),
                    vec2f(uvMax, uvMax)
                ),
                Vertex(
                    vec2f(vertexMax, vertexMin),
                    vec2f(uvMax, uvMin)
                ),
                Vertex(
                    vec2f(vertexMin, vertexMax),
                    vec2f(uvMin, uvMax)
                ),
                Vertex(
                    vec2f(vertexMax, vertexMin),
                    vec2f(uvMax, uvMin)
                ),
                Vertex(
                    vec2f(vertexMin, vertexMin),
                    vec2f(uvMin, uvMin)
                ),
            ];
            buffer = new GLBuffer(opengl, GL_ARRAY_BUFFER, GL_STATIC_DRAW, shape.dup);
            specification = new VertexSpecification!Vertex(_program);
            
            buffer.bind;
            specification.use;
        }
        
        projection = mat4.orthographic(
            0, WIDTH,
            0, HEIGHT,
            0.0, 5.0,
        );
        
        _program.uniform("projection").set(projection);
        _program.uniform("view").set(view);
    }
    
    @property GLProgram program()
    {
        return _program;
    }
    
    void close()
    {
        _program.destroy;
        buffer.destroy;
    }
    
    void update()
    {
        immutable scaledPlayerPosition = player.screenPosition - vec2(WIDTH - TEXTURE_SIZE + 2, HEIGHT + TEXTURE_SIZE / 2) / vec2(2, 2);
        immutable viewTarget = vec3f(scaledPlayerPosition, 0);
        view = mat4.lookAt(
            viewTarget + vec3f(0, 0, 1),
            viewTarget,
            vec3f(0, 1, 0),
        );
        
        program.uniform("view").set(view);
        
        if(firstUpdate)
        {
            firstUpdate = false;
            
            textureAtlas.use;
            program.uniform("atlasSizePixels").set(atlasSizePixels);
            program.uniform("atlasSizeTiles").set(atlasSizeTiles);
            program.uniform("atlasTileSizeFloating").set(TEXTURE_SIZE / cast(float)atlasSizePixels);
        }
    }
    
    void copy(TextureData data, int x, int y, real rotation = 0, vec3f color = vec3f(1, 1, 1))
    {
        enum halfSize = TEXTURE_SIZE / 2f;
        
        program.uniform("model").set(
            mat4.translation(vec3f(cast(float)x, cast(float)y, 0)) *
            mat4.translation(vec3f(halfSize, halfSize, 0)) *
            mat4.rotation(rotation.radians, vec3f(0, 0, 1)) *
            mat4.translation(vec3f(-halfSize, -halfSize, 0)) *
            mat4.scaling(vec3f(TEXTURE_SIZE, TEXTURE_SIZE, 0))
        );
        program.uniform("colorMask").set(color);
        program.uniform("index").set(data.index);
        glDrawArrays(GL_TRIANGLES, 0, cast(int)(buffer.size / specification.vertexSize));
    }
}

private string[] read_lines(string filename)
{
    return filename.readText.split("\n");
}

