module pacman.texture;

import std.experimental.logger;
import std.file;

import gfm.sdl2;

import pacman.globals;

private SDL2Texture missingTexture;
private SDL2Texture[string] loadedTextures;

SDL_PixelFormat get_format_data(uint format) //TOOD: private again
{
    SDL_PixelFormat result;
    int bpp;
    uint r;
    uint g;
    uint b;
    uint a;
    
    SDL_PixelFormatEnumToMasks(
        format,
        &bpp,
        &r,
        &g,
        &b,
        &a
    );
    
    result.format = format;
    result.BitsPerPixel = cast(ubyte)bpp;
    result.BytesPerPixel = cast(ubyte)bpp / 8;
    result.Rmask = r;
    result.Gmask = g;
    result.Bmask = b;
    result.Amask = a;
    
    return result;
}

private SDL2Texture load_texture(string path, uint pixelFormat = SDL_PIXELFORMAT_RGBA8888)
{
    if(!path.exists)
        fatal("Attempted to load missing texture: ", path);
    
    info("Caching texture ", path);
    
    auto formatData = get_format_data(pixelFormat);
    auto surfaceRaw = sdlImage.load(path); scope(exit) surfaceRaw.close;
    auto surface = surfaceRaw.convert(&formatData); scope(exit) surface.close;
    
    assert(surface.width == TEXTURE_SIZE);
    assert(surface.height == TEXTURE_SIZE);
    
    auto result = new SDL2Texture(
        renderer,
        pixelFormat,
        SDL_TEXTUREACCESS_STATIC,
        surface.width, surface.height
    );
    loadedTextures[path] = result;
    
    result.updateTexture(surface.pixels, cast(int)surface.pitch);
    result.setBlendMode(SDL_BLENDMODE_BLEND);
    
    return result;
}

SDL2Texture get_texture(string path)
{
    if(!missingTexture)
        missingTexture = load_texture("res/missing.png");
    
    if(!path.exists)
    {
        warningf("Texture %s does not exist, using fallback texture", path);
        
        return missingTexture;
    }
    
    auto texture = path in loadedTextures;
    
    if(texture)
        return *texture;
    else
        return load_texture(path);
}

void close_textures()
{
    foreach(texture; loadedTextures.values)
        texture.close;
}
