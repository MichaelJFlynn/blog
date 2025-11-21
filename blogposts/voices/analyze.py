import wave
import numpy
import struct

voices = wave.open('crowded_bar.wav', 'r')

print "Number of channels: " + str(voices.getnchannels())
print "Sample bytewidth: " + str(voices.getsampwidth())
print "Framerate: " + str(voices.getframerate())
print "Number of frames: " + str(voices.getnframes())
print "Example Frame: " + str(voices.readframes(1))

num_chunks = 10000
chunk_width = voices.getnframes()/num_chunks

           ## unpack little-endian ints
samples =  [[struct.unpack("<h", 
                           ## read the first 2 bytes of 1 frame. The
                           ## total sample if 4 bytes long, 1 for each
                           ## sample, and since the output is a tuple
                           ## take the 0th output.
                           voices.readframes(1)[0:2])[0] 
             ## for all samples in the chunk
             for i in range(chunk_width)] 
            ## for all chunks in the recording.
            for y in range(num_chunks)]    

print "Starting fft..."
def print_and_fft(x, i):
    print i
    return numpy.fft.fft(x)
transformed = numpy.matrix(map(print_and_fft, samples, range(len(samples))))
# transformed = transformed[,:]
means = [0 for x in transformed[:,0]] 
# means = transformed[:,0]
transformed = transformed[:,1:(transformed.shape[1]/2+1)]
print "Done fft."

mean_zero = numpy.apply_along_axis(lambda x: (x - numpy.mean(x)), 0, transformed)
mean_zero = numpy.matrix(mean_zero)
cov = numpy.dot(mean_zero.getH(), mean_zero)
print "Starting eigenvector solve..."
w, v = numpy.linalg.eig(cov)
# print w[:100]
# print numpy.abs(w[:100])

def print_and_ifft(x, i):
    print i
    return numpy.fft.ifft(x)

def projected_spectrum(component): 
    return numpy.dot(numpy.dot(transformed.conj(), v[:,component]), v.transpose()[component,:])


def index_limits():
    return (int(200 *  351 / num_chunks), int(900 * 351 / num_chunks))

def write_component_to_file(component):
    projected = projected_spectrum(component)
    projected = numpy.column_stack((means, projected, numpy.fliplr(projected.conj())))
    inverted = map(print_and_ifft, projected.tolist(), range(len(projected)))
    first_component = wave.open(str(component) + '.wav', 'w')
    width = projected.shape[0]
    height = projected.shape[1]
    first_component.setparams(
        (1, # nchannels
         2, # sampwidth
         voices.getframerate(), # framerate
         width * height, 
         voices.getcomptype(),
         voices.getcompname()))
    frames = "".join(["".join([struct.pack("<h", int(i.real)) for i in x]) for x in inverted])     
    first_component.writeframes(frames)
    first_component.close()
    print "Wrote component " + str(component) + " to file."

write_component_to_file(0)
write_component_to_file(1)
write_component_to_file(2)
write_component_to_file(3)
write_component_to_file(4)
write_component_to_file(10)
write_component_to_file(50)
write_component_to_file(100)
write_component_to_file(500)

def write_components_to_file(component):
    projected = projected_spectrum(component)
    projected = numpy.column_stack((means, projected, numpy.fliplr(projected.conj())))
    inverted = map(print_and_ifft, projected.tolist(), range(len(projected)))
    first_component = wave.open('components.wav', 'w')
    width = projected.shape[0]
    height = projected.shape[1]
    first_component.setparams(
        (1, # nchannels
         2, # sampwidth
         voices.getframerate(), # framerate
         width * height, 
         voices.getcomptype(),
         voices.getcompname()))
    frames = "".join(["".join([struct.pack("<h", int(i.real)) for i in x]) for x in inverted])     
    first_component.writeframes(frames)
    first_component.close()
    print "Wrote components to file."

#write_components_to_file()
