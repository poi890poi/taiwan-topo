# base (0x2000) + region x lang x style
# where, ...
# - 2nd hex, region -> taiwan(0), taipei(1)
# - 3rd hex, lang   -> en(0), zh(1),
# - 4th hex, style  -> jing(0), outdoor(1), contrast_outdoor(2), bw(3)

# target SUITE, no default
ifeq ($(SUITE),taiwan_jing)
REGION := Taiwan
LANG := zh
CODE_PAGE := 950
EXTRACT_FILE := taiwan-latest.osm.pbf
TYP := jing
STYLE := jing
STYLE_NAME := jing
MAPID := $(shell printf %d 0x2010)
else ifeq ($(SUITE),taiwan_odr)
REGION := Taiwan
LANG := zh
CODE_PAGE := 950
EXTRACT_FILE := taiwan-latest.osm.pbf
TYP := outdoor
STYLE := fzk
STYLE_NAME := odr
MAPID := $(shell printf %d 0x2011)
else ifeq ($(SUITE),taiwan_odc)
REGION := Taiwan
LANG := zh
CODE_PAGE := 950
EXTRACT_FILE := taiwan-latest.osm.pbf
TYP := outdoorc
STYLE := swisspopo
STYLE_NAME := odc
MAPID := $(shell printf %d 0x2012)
else ifeq ($(SUITE),taiwan_bw)
REGION := Taiwan
LANG := zh
CODE_PAGE := 950
EXTRACT_FILE := taiwan-latest.osm.pbf
TYP := bw
STYLE := swisspopo
STYLE_NAME := bw
MAPID := $(shell printf %d 0x2013)
else ifeq ($(SUITE),taipei_odc)
REGION := Taipei
LANG := zh
CODE_PAGE := 950
EXTRACT_FILE := taiwan-latest.osm.pbf
POLY_FILE := Taipei.poly
TYP := outdoorc
STYLE := swisspopo
STYLE_NAME := odc
MAPID := $(shell printf %d 0x2112)
else ifeq ($(SUITE),taipei_bw)
REGION := Taipei
LANG := zh
CODE_PAGE := 950
EXTRACT_FILE := taiwan-latest.osm.pbf
POLY_FILE := Taipei.poly
TYP := bw
STYLE := swisspopo
STYLE_NAME := bw
MAPID := $(shell printf %d 0x2113)
else ifeq ($(SUITE),taipei_en_bw)
REGION := Taipei
LANG := en
CODE_PAGE := 950
EXTRACT_FILE := taiwan-latest.osm.pbf
POLY_FILE := Taipei.poly
TYP := bw
STYLE := swisspopo
STYLE_NAME := bw
MAPID := $(shell printf %d 0x2103)
else ifeq ($(SUITE),kyushu_bw)
REGION := Kyushu
LANG := en
CODE_PAGE := 950
#CODE_PAGE := 1252
EXTRACT_FILE := japan-latest.osm.pbf
POLY_FILE := Kyushu.poly
TYP := bw
STYLE := swisspopo
STYLE_NAME := bw
MAPID := $(shell printf %d 0x2313)
else 
    $(error Error: SUITE not specified. Please specify SUITE=[taiwan|taipei]_[jing|outdoor|outdoorc])
endif

# auto variables
VERSION := $(shell date +%Y.%m.%d)

NAME_LONG := SRTM3.OSM.$(STYLE_NAME) - $(REGION) TOPO v$(VERSION) (by Rudy)
NAME_SHORT := SRTM3.OSM.$(STYLE_NAME) - $(REGION) TOPO v$(VERSION) (by Rudy)
NAME_WORD := $(REGION)_TOPO_$(STYLE_NAME)

# finetune options
JAVACMD_OPTIONS := -Xmx4096M

# directory variables
ROOT_DIR := $(shell pwd)
TOOLS_DIR := $(ROOT_DIR)/tools
SEA_DIR := $(ROOT_DIR)/sea
BOUNDS_DIR := $(ROOT_DIR)/bounds
CITIES_DIR := $(ROOT_DIR)/cities
POLIES_DIR := $(ROOT_DIR)/polies
ELEVATIONS_DIR := $(ROOT_DIR)/osm_elevations
EXTRACT_DIR := $(ROOT_DIR)/work/extracts
DATA_DIR := $(ROOT_DIR)/work/$(REGION)/data$(MAPID)
MAP_DIR := $(ROOT_DIR)/work/$(REGION)/$(NAME_WORD)
BUILD_DIR := $(ROOT_DIR)/install

ELEVATION := $(ELEVATIONS_DIR)/ele_taiwan_10_100_500_view1,srtm1,view3,srtm3.osm.pbf
EXTRACT := $(EXTRACT_DIR)/$(EXTRACT_FILE)
CITY := $(CITIES_DIR)/TW.zip
DATA := $(DATA_DIR)/.done
MAP := $(MAP_DIR)/.done
GMAP := $(BUILD_DIR)/$(REGION)_$(LANG)_$(STYLE_NAME).gmap
GMAPSUPP := $(BUILD_DIR)/gmapsupp_$(REGION)_$(LANG)_$(STYLE_NAME).img

TARGETS := $(GMAPSUPP) $(GMAP)

ifeq ($(shell uname),Darwin)
MD5_CMD := md5 -q $(EXTRACT)
JMC_CMD := jmc/osx/jmc_cli
else
MD5_CMD := md5sum $(EXTRACT) | cut -d' ' -f1
JMC_CMD := jmc/linux/jmc_cli
endif

all: $(TARGETS)

clean:
	-rm -rf $(TARGETS)
	-rm -rf $(MAP_DIR)

distclean: clean
	-rm -rf $(DATA_DIR)
	-rm -rf $(EXTRACT)

install: all
	[ -d "$(INSTALL_DIR)" ]
	cp -r $(TARGETS) $(INSTALL_DIR)
	cat srtm3_osm_taiwan_topo.html | sed \
	    -e "s|__version__|$(VERSION)|g" > $(INSTALL_DIR)/srtm3_osm_taiwan_topo.html

$(GMAP): $(MAP)
	-rm -rf $@
	mkdir -p $(BUILD_DIR)
	cd $(MAP_DIR) && \
	    rm -rf $@ && \
	    cat $(ROOT_DIR)/jmc_cli.cfg | sed \
	    	-e "s|__map_dir__|$(MAP_DIR)|g" \
		-e "s|__name_word__|$(NAME_WORD)|g" \
		-e "s|__mapid__|$(MAPID)|g" > jmc_cli.cfg && \
	    $(TOOLS_DIR)/$(JMC_CMD) -v -config="$(MAP_DIR)/jmc_cli.cfg"
	cp -a "$(MAP_DIR)/$(NAME_SHORT).gmap" $@ || cp -a "$(MAP_DIR)/$(NAME_WORD).gmap" $@

$(GMAPSUPP): $(MAP)
	-rm -rf $@
	mkdir -p $(BUILD_DIR)
	cd $(MAP_DIR) && \
	    java $(JAVACMD_OPTIONS) -jar $(TOOLS_DIR)/mkgmap/mkgmap.jar \
	        --license-file=$(ROOT_DIR)/license.txt \
	        --index \
	        --gmapsupp \
	        --product-id=1 \
	        --family-id=$(MAPID) \
	        --series-name="$(NAME_WORD)" \
	        --family-name="$(NAME_SHORT)" \
	        --description="$(NAME_SHORT)" \
	        --overview-mapnumber=$(MAPID)0000 \
	        --product-version=$(VERSION) \
		$(MAPID)*.img $(MAPID).TYP
	cp $(MAP_DIR)/gmapsupp.img $@

ifeq ($(LANG),zh) 
NTL := name,name:zh,name:en
else ifeq ($(LANG),en)
NTL := name:zh,name:en,name
else
    $(error Error: LANG not specified. something wrong at SUITE handlation)
endif

$(MAP): $(DATA)
	rm -rf $(MAP_DIR)
	mkdir -p $(MAP_DIR)
	cd $(MAP_DIR) && \
	    cat $(ROOT_DIR)/TYPs/$(TYP).txt | sed \
	    	-e "s|ä|a|g" \
	    	-e "s|é|e|g" \
	    	-e "s|ß|b|g" \
	    	-e "s|ü|u|g" \
	    	-e "s|ö|o|g" \
	    	-e "s|FID=.*|FID=$(MAPID)|g" \
		-e "s|CodePage=.*|CodePage=$(CODE_PAGE)|g" > $(TYP).txt && \
	    java $(JAVACMD_OPTIONS) -jar $(TOOLS_DIR)/mkgmap/mkgmap.jar \
	    	--product-id=1 \
		--family-id=$(MAPID) \
		$(TYP).txt && \
	    cp $(TYP).typ $(MAPID).TYP && \
	    mkdir $(MAP_DIR)/style && \
	    cp -a $(ROOT_DIR)/styles/$(STYLE) $(MAP_DIR)/style/$(STYLE) && \
	    cp $(ROOT_DIR)/styles/style-translations $(MAP_DIR)/ && \
	    cat $(ROOT_DIR)/mkgmap.cfg | sed \
		-e "s|__root_dir__|$(ROOT_DIR)|g" \
		-e "s|__map_dir__|$(MAP_DIR)|g" \
		-e "s|__version__|$(VERSION)|g" \
		-e "s|__style__|$(STYLE)|g" \
		-e "s|__name_tag_list__|$(NTL)|g" \
		-e "s|__code_page__|$(CODE_PAGE)|g" \
		-e "s|__name_long__|$(NAME_LONG)|g" \
		-e "s|__name_short__|$(NAME_SHORT)|g" \
		-e "s|__name_word__|$(NAME_WORD)|g" \
		-e "s|__mapid__|$(MAPID)|g" > mkgmap.cfg && \
	    cat $(DATA_DIR)/template.args | sed \
	    	-e "s|description: \(.*\)|description: \\1 $(VERSION)|g" \
	    	-e "s|input-file: \(.*\)|input-file: $(DATA_DIR)/\\1|g" >> mkgmap.cfg && \
	    java $(JAVACMD_OPTIONS) -jar $(TOOLS_DIR)/mkgmap/mkgmap.jar \
	    	--max-jobs=2 \
	    	-c mkgmap.cfg \
		--check-styles
	touch $(MAP)

$(EXTRACT):
	mkdir -p $(EXTRACT_DIR)
	cd $(EXTRACT_DIR) && \
	    curl http://download.geofabrik.de/asia/$(EXTRACT_FILE) -o $(EXTRACT_FILE) && \
	    curl http://download.geofabrik.de/asia/$(EXTRACT_FILE).md5 -o $(EXTRACT_FILE).md5 && \
	    [ "$$($(MD5_CMD))" == "$$(cat $(EXTRACT_FILE).md5 | cut -d' ' -f1)" ] || \
	    	( rm -rf $@ && false )

# OSMOSIS_OPTS
ifneq (,$(strip $(POLY_FILE)))
    OSMOSIS_OPTS := $(strip $(OSMOSIS_OPTS) --bounding-polygon file="$(POLIES_DIR)/$(POLY_FILE)")
endif

$(DATA): $(EXTRACT) $(ELEVATION)
	rm -rf $(DATA_DIR)
	mkdir -p $(DATA_DIR)
	export JAVACMD_OPTIONS=$(JAVACMD_OPTIONS) && cd $(DATA_DIR) && \
	    sh $(TOOLS_DIR)/osmosis/bin/osmosis \
		--read-pbf $(EXTRACT) \
		--read-pbf $(ELEVATION) \
		--merge \
		$(OSMOSIS_OPTS) \
		--write-pbf $(REGION).osm.pbf \
		omitmetadata=true && \
	    java $(JAVACMD_OPTIONS) -jar $(TOOLS_DIR)/splitter/splitter.jar \
	    	--geonames-file=$(CITY) \
		--no-trim \
		--precomp-sea=$(SEA_DIR) \
	        --keep-complete=true \
		--mapid=$(MAPID)0001 \
		--max-areas=4096 \
		--max-nodes=800000 \
		--search-limit=1000000000 \
		--output=xml \
		--output-dir=$(DATA_DIR) \
		$(REGION).osm.pbf
	touch $(DATA)
