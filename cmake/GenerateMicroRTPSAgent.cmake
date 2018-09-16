# Cmake module to generate micro-RTPS agent code
# Depends on:
# - PROJECT_NAME
# - PX4_FIRMWARE_MSG_DIR/tools/uorb_rtps_message_ids.yaml
# - FASTRTPSGEN_DIR
# - ROS_UORB_MSGS_DIR

# Add the python scripts dir from PX4 msg/tools to PYTHONPATH
set(ENV{PYTHONPATH} "$ENV{PYTHONPATH}:${PX4_FIRMWARE_MSG_DIR}/tools/")

# Check if the RTPS ID's mapper yaml file exists and if yes, change the msg naming to PascalCase
if(EXISTS ${PX4_FIRMWARE_MSG_DIR}/tools/uorb_rtps_message_ids.yaml)
    set(RTPS_ID_YAML_FILE ${CMAKE_CURRENT_SOURCE_DIR}/msg/templates/uorb_rtps_message_ids.yaml)

    # Parse the RTPS IDs for each uORB msg into the counterparts for ROS
    execute_process(
        COMMAND ${PYTHON_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/scripts/PX42ROSRTPSIds.py
            --input-file ${PX4_FIRMWARE_MSG_DIR}/tools/uorb_rtps_message_ids.yaml
            --output-file ${RTPS_ID_YAML_FILE}
        )
    message(STATUS "RTPS msg ID yaml file: ${RTPS_ID_YAML_FILE}")
else()
    message(FATAL_ERROR "RTPS msg ID yaml file \"${PX4_FIRMWARE_MSG_DIR}/tools/uorb_rtps_message_ids.yaml\" not found!")
endif()

# Set the micro-RTPS agent code dir
set(MICRORTPS_AGENT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src/micrortps_agent)

# Set the list of files to be compiled
set(MICRORTPS_AGENT_FILES ${MICRORTPS_AGENT_DIR}/microRTPS_agent.cpp)
list(APPEND MICRORTPS_AGENT_FILES ${MICRORTPS_AGENT_DIR}/microRTPS_transport.h)
list(APPEND MICRORTPS_AGENT_FILES ${MICRORTPS_AGENT_DIR}/microRTPS_transport.cpp)
list(APPEND MICRORTPS_AGENT_FILES ${MICRORTPS_AGENT_DIR}/RtpsTopics.h)
list(APPEND MICRORTPS_AGENT_FILES ${MICRORTPS_AGENT_DIR}/RtpsTopics.cpp)
foreach(topic ${ROS_UORB_NAMES})
    list(APPEND MICRORTPS_AGENT_FILES ${MICRORTPS_AGENT_DIR}/${topic}_.cpp)
    list(APPEND MICRORTPS_AGENT_FILES ${MICRORTPS_AGENT_DIR}/${topic}_Publisher.cpp)
    list(APPEND MICRORTPS_AGENT_FILES ${MICRORTPS_AGENT_DIR}/${topic}_Publisher.h)
    list(APPEND MICRORTPS_AGENT_FILES ${MICRORTPS_AGENT_DIR}/${topic}_Subscriber.cpp)
    list(APPEND MICRORTPS_AGENT_FILES ${MICRORTPS_AGENT_DIR}/${topic}_Subscriber.h)
    list(APPEND MICRORTPS_AGENT_FILES ${MICRORTPS_AGENT_DIR}/${topic}_PubSubTypes.cpp)
    list(APPEND MICRORTPS_AGENT_FILES ${MICRORTPS_AGENT_DIR}/${topic}_PubSubTypes.h)
endforeach()

# Generates the micro-RTPS agent code after the IDL msgs are generated
add_custom_command(
    OUTPUT ${MICRORTPS_AGENT_FILES}
    DEPENDS ${PROJECT_NAME}
        ${PYTHON_EXECUTABLE} ${PX4_FIRMWARE_MSG_DIR}/tools/generate_microRTPS_bridge.py
        $ENV{FASTRTPSGEN_DIR}
        ${ROS_UORB_MSGS_DIR}
    COMMAND ${PYTHON_EXECUTABLE} ${PX4_FIRMWARE_MSG_DIR}/tools/generate_microRTPS_bridge.py
        --fastrtpsgen-dir $ENV{FASTRTPSGEN_DIR}
        --fastrtpsgen-include ${CMAKE_CURRENT_BINARY_DIR}/rosidl_generator_dds_idl/
        --send ${ROS_UORB_MSGS_DIR}
        --receive ${ROS_UORB_MSGS_DIR}
        --topic-msg-dir ${CMAKE_CURRENT_SOURCE_DIR}/msg
        --urtps-templates-dir "templates"
        --agent
        --agent-outdir ${MICRORTPS_AGENT_DIR}
        --package ${PROJECT_NAME}
        --idl-dir ${CMAKE_CURRENT_BINARY_DIR}/rosidl_generator_dds_idl/${PROJECT_NAME}/msg/dds_opensplice
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Generating micro-RTPS agent code..."
)

set(MICRORTPS_AGENT_FILES "${MICRORTPS_AGENT_FILES}" CACHE INTERNAL "MICRORTPS_AGENT_FILES")