import numpy as np
from openslide import OpenSlide


def read_img(slide_file, location, level, size):
	slide = OpenSlide(slide_file)
	location = [int(x) for x in location]
	size = [int(x) for x in size]
	img = np.array(slide.read_region(location, int(level), size).convert(mode='RGB'))
	return img



