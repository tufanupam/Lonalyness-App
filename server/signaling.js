/**
 * AI Muse — WebRTC Signaling Server
 *
 * Socket.IO-based signaling server for WebRTC peer connections.
 * Handles room management, offer/answer exchange, and ICE candidate relay.
 */

const { Server } = require('socket.io');

/**
 * Attach the signaling server to an existing HTTP server.
 * @param {import('http').Server} httpServer
 */
function createSignalingServer(httpServer) {
    const io = new Server(httpServer, {
        cors: {
            origin: '*',
            methods: ['GET', 'POST'],
        },
        path: '/signaling',
    });

    // Track rooms and their participants
    const rooms = new Map();

    io.on('connection', (socket) => {
        console.log(`🔌 Client connected: ${socket.id}`);

        /**
         * Join a call room.
         */
        socket.on('join', ({ room, userId }) => {
            socket.join(room);

            if (!rooms.has(room)) {
                rooms.set(room, new Set());
            }
            rooms.get(room).add(socket.id);

            console.log(`👤 ${socket.id} joined room: ${room}`);

            // Notify others in the room
            socket.to(room).emit('user-joined', {
                userId,
                socketId: socket.id,
            });

            // Send current participants to the joiner
            const participants = Array.from(rooms.get(room)).filter(
                (id) => id !== socket.id
            );
            socket.emit('room-info', { room, participants });
        });

        /**
         * Relay WebRTC offer to target peer.
         */
        socket.on('offer', ({ room, sdp, target }) => {
            console.log(`📤 Offer from ${socket.id} to ${target || 'room'}`);
            if (target) {
                io.to(target).emit('offer', { sdp, from: socket.id });
            } else {
                socket.to(room).emit('offer', { sdp, from: socket.id });
            }
        });

        /**
         * Relay WebRTC answer to target peer.
         */
        socket.on('answer', ({ room, sdp, target }) => {
            console.log(`📥 Answer from ${socket.id} to ${target}`);
            if (target) {
                io.to(target).emit('answer', { sdp, from: socket.id });
            } else {
                socket.to(room).emit('answer', { sdp, from: socket.id });
            }
        });

        /**
         * Relay ICE candidates to target peer.
         */
        socket.on('ice-candidate', ({ room, candidate, target }) => {
            if (target) {
                io.to(target).emit('ice-candidate', {
                    candidate,
                    from: socket.id,
                });
            } else {
                socket.to(room).emit('ice-candidate', {
                    candidate,
                    from: socket.id,
                });
            }
        });

        /**
         * Handle disconnection.
         */
        socket.on('disconnect', () => {
            console.log(`❌ Client disconnected: ${socket.id}`);

            // Remove from all rooms
            rooms.forEach((participants, room) => {
                if (participants.has(socket.id)) {
                    participants.delete(socket.id);
                    socket.to(room).emit('user-left', { socketId: socket.id });

                    // Clean up empty rooms
                    if (participants.size === 0) {
                        rooms.delete(room);
                    }
                }
            });
        });
    });

    console.log('📡 WebRTC signaling server attached');
    return io;
}

module.exports = { createSignalingServer };
